module pc_tb();
    logic clk;
    logic rst;
    logic pc_we;
    logic next_pc;

    logic pc;

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
        
    end



endmodule
