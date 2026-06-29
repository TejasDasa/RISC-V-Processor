
module regfile_tb;

    logic        clk;
    logic        we;

    logic [4:0]  rs1_addr;
    logic [4:0]  rs2_addr;
    logic [4:0]  rd_addr;

    logic [31:0] rd_data;

    logic [31:0] rs1_data;
    logic [31:0] rs2_data;

    regfile dut (
        .clk(clk),
        .we(we),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        we = 1'b0;
        rs1_addr = 5'd0;
        rs2_addr = 5'd0;
        rd_addr = 5'd0;
        rd_data = 32'd0;

        #1;

        if (rs1_data != 32'd0) $error("x0 rs1 read failed: expected 0, got %0d", rs1_data);

        if (rs2_data != 32'd0) $error("x0 rs2 read failed: expected 0, got %0d", rs2_data);

        we = 1'b1;
        rd_addr = 5'd1;
        rd_data = 32'd123;

        @(posedge clk);
        #1;

        //The write happens at the next rising edge of clk.

        we = 1'b0;
        rs1_addr = 5'd1;
        #1;

        if (rs1_data != 32'd123) $error("x1 write/read failed: expected 123, got %0d", rs1_data);

        we = 1'b1;
        rd_addr = 5'd2;
        rd_data = 32'd456;

        @(posedge clk);
        #1;

        //The write happens at the next rising edge of clk.

        we = 1'b0;
        rs2_addr = 5'd2;
        #1;

        if (rs2_data != 32'd456) $error("x2 write/read failed: expected 456, got %0d", rs2_data);




        $display("PASS: all regfile tests passed");
        $finish;

    end
endmodule
