module pc_tb();
    logic clk;
    logic rst;
    logic pc_we;
    logic [31:0] next_pc;

    logic [31:0] pc;

    pc dut (
        .clk(clk),
        .rst(rst),
        .pc_we(pc_we),
        .next_pc(next_pc),
        .pc(pc)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1'b0;
        pc_we = 1'b0;
        next_pc = 32'b0;

        // Case 1, instantiate next_pc but keep pc_we low
        next_pc = 32'd5;
        pc_we = 1'b0;

        @(posedge clk);
        #1;

        if (pc != 32'b0) $error("Write enable low test failed, expected 0, got %0d", pc);


        // Case 2, instantiate next_pc but hold pc_we high
        pc_we = 1'b1;

        @(posedge clk);
        #1;

        if (pc != 32'd5) $error("Write enable high test failed, expected 5, got %0d", pc);

        // Case 3, check reset
        rst = 1'b1;

        @(posedge clk);
        #1;

        if (pc != 32'd0) $error("Reset test failed, expected 0, got %0d", pc);
        

        $display("ALL PC TESTS PASSED");
        $finish;
    end

endmodule
