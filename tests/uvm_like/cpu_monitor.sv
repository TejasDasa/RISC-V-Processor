module cpu_monitor (
    input logic        clk,
    input logic        rst,

    input logic        retire_valid,
    input logic [31:0] retire_pc,
    input logic [31:0] retire_instr,
    input logic        retire_reg_write,
    input logic [4:0]  retire_rd,
    input logic [31:0] retire_rd_data
);

int unsigned retire_count;

`ifdef TRACE_RETIRE
    always_ff @(posedge clk) begin
        if (rst) begin
            retire_count <= 0;
        end else if (retire_valid) begin
            retire_count <= retire_count + 1;

            $display(
                "RETIRE pc=%08h instr=%08h regwrite=%0d rd=%0d data=%08h",
                retire_pc,
                retire_instr,
                retire_reg_write,
                retire_rd,
                retire_rd_data
            );
        end
    end
`else
    always_ff @(posedge clk) begin
        if (rst)
            retire_count <= 0;
        else if (retire_valid)
            retire_count <= retire_count + 1;
    end
`endif

endmodule
