module core(
    input logic clk,
    input logic rst,

    output logic [31:0] debug_pc,
    output logic [31:0] debug_instr
);

    logic [31:0] pc_current;
    logic [31:0] next_pc;
    logic [31:0] instr;

    pc pc_inst (
        .clk(clk),
        .rst(rst),
        .pc_we(1'b1),
        .next_pc(next_pc),
        .pc(pc_current)
    );

    imem imem_inst (
        .addr(pc_current),
        .instr(instr)
    );

    assign next_pc = pc_current + 32'd4;

    assign debug_pc = pc_current;
    assign debug_instr = instr;

endmodule
