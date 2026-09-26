module cpu_monitor (
    input logic        clk,
    input logic        rst,

    input logic        retire_valid,
    input logic [31:0] retire_pc,
    input logic [31:0] retire_instr,

    input logic        retire_reg_write,
    input logic [4:0]  retire_rd,
    input logic [31:0] retire_rd_data,

    input logic        retire_exception,
    input logic        retire_interrupt,
    input logic [31:0] retire_cause
);

    int unsigned retire_count;
    int unsigned exception_count;
    int unsigned interrupt_count;

    always_ff @(posedge clk) begin
        if (rst) begin
            retire_count    <= 0;
            exception_count <= 0;
            interrupt_count <= 0;
        end
        else begin
            if (retire_valid) begin
                retire_count <= retire_count + 1;

`ifdef TRACE_RETIRE
                $display(
                    "RETIRE pc=%08h instr=%08h regwrite=%0d rd=%0d data=%08h",
                    retire_pc,
                    retire_instr,
                    retire_reg_write,
                    retire_rd,
                    retire_rd_data
                );
`endif
            end

            // Kept distinct from "RETIRE" so the random-flow
            // retire parser ignores these lines.
            if (retire_exception || retire_interrupt) begin
                if (retire_interrupt)
                    interrupt_count <= interrupt_count + 1;
                else
                    exception_count <= exception_count + 1;

`ifdef TRACE_RETIRE
                $display(
                    "TRAP_EVENT kind=%s pc=%08h instr=%08h cause=%08h",
                    retire_interrupt ? "interrupt" : "exception",
                    retire_pc,
                    retire_instr,
                    retire_cause
                );
`endif
            end
        end
    end

    final begin
        $display(
            "MONITOR retired=%0d exceptions=%0d interrupts=%0d",
            retire_count,
            exception_count,
            interrupt_count
        );
    end

endmodule
