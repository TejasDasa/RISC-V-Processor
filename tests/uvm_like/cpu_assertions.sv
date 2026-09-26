module cpu_assertions (
    input logic clk,
    input logic rst,

    input logic        load_use_hazard,
    input logic        ex_redirect,
    input logic [31:0] ex_redirect_pc,

    input logic        trap_enter,
    input logic [31:0] mtvec,

    input logic        ex_take_mret,
    input logic [31:0] mepc,

    input logic [31:0] trap_cause,
    input logic        global_irq_enable,
    input logic        timer_irq_enable,
    input logic        timer_irq_pending,

    input logic [31:0] pc_current,

    input logic        id_ex_valid,
    input logic [31:0] id_ex_pc,
    input logic        ex_mem_valid,
    input logic        mem_wb_valid,

    input logic        bus_read_en,
    input logic        bus_write_en,

    input logic        wb_reg_write_en,
    input logic [4:0]  wb_rd_addr,

    input logic [31:0] x0,

    // Retirement stream
    input logic        retire_valid,
    input logic [31:0] retire_pc,
    input logic [31:0] retire_instr,
    input logic        retire_exception,
    input logic        retire_interrupt,
    input logic [31:0] retire_cause
);

    // ------------------------------------------------------------
    // Retirement-level precise trap checks
    // ------------------------------------------------------------

    localparam logic [31:0] MRET_INSTR = 32'h3020_0073;

    logic trap_event;

    assign trap_event =
        retire_exception || retire_interrupt;

    // A trapped instruction is reported, never retired.
    ap_trap_event_not_retired:
        assert property (@(posedge clk)
            disable iff (rst)
            trap_event |-> !retire_valid
        );

    // Every trap produces exactly one trap event, two cycles later
    // (EX -> MEM -> WB), i.e. after all older instructions.
    ap_trap_event_timing:
        assert property (@(posedge clk)
            disable iff (rst)
            trap_event == $past(trap_enter, 2)
        );

    ap_trap_event_kind:
        assert property (@(posedge clk)
            disable iff (rst)
            trap_event |-> (retire_interrupt == retire_cause[31])
        );

    // Expected PC of the next retirement:
    //   after a trap event   -> mtvec (first handler instruction)
    //   after an MRET retire -> mepc
    // Any other retirement in between would be a younger or
    // wrong-path instruction committing.
    logic        expect_next_valid;
    logic [31:0] expect_next_pc;

    always_ff @(posedge clk) begin
        if (rst) begin
            expect_next_valid <= 1'b0;
            expect_next_pc    <= 32'b0;
        end
        else if (trap_event) begin
            expect_next_valid <= 1'b1;
            expect_next_pc    <= mtvec;
        end
        else if (retire_valid && (retire_instr == MRET_INSTR)) begin
            expect_next_valid <= 1'b1;
            expect_next_pc    <= mepc;
        end
        else if (retire_valid) begin
            expect_next_valid <= 1'b0;
        end
    end

    ap_retire_after_trap_or_mret:
        assert property (@(posedge clk)
            disable iff (rst)
            (expect_next_valid && retire_valid) |->
                (retire_pc == expect_next_pc)
        );

    // ------------------------------------------------------------
    // Architectural invariants
    // ------------------------------------------------------------

    // x0 must always contain zero.
    ap_x0_zero:
        assert property (@(posedge clk)
            disable iff (rst)
            x0 == 32'b0
        );

    // Never architecturally write x0.
    ap_no_x0_write:
        assert property (@(posedge clk)
            disable iff (rst)
            wb_reg_write_en |-> (wb_rd_addr != 5'd0)
        );


    // ------------------------------------------------------------
    // Pipeline validity
    // ------------------------------------------------------------

    // Invalid MEM-stage instructions cannot access memory.
    ap_valid_read:
        assert property (@(posedge clk)
            disable iff (rst)
            bus_read_en |-> ex_mem_valid
        );

    ap_valid_write:
        assert property (@(posedge clk)
            disable iff (rst)
            bus_write_en |-> ex_mem_valid
        );

    // Invalid WB entries cannot modify the register file.
    ap_valid_reg_write:
        assert property (@(posedge clk)
            disable iff (rst)
            wb_reg_write_en |-> mem_wb_valid
        );


    // ------------------------------------------------------------
    // Load-use hazard behavior
    // ------------------------------------------------------------

    // A load-use hazard must freeze the PC, unless an EX redirect
    // (e.g. an interrupt taken on the load) overrides the stall.
    ap_load_use_pc_stall:
        assert property (@(posedge clk)
            disable iff (rst)
            (load_use_hazard && !ex_redirect) |=> $stable(pc_current)
        );

    // A load-use hazard must inject a bubble into EX.
    ap_load_use_bubble:
        assert property (@(posedge clk)
            disable iff (rst)
            load_use_hazard |=> !id_ex_valid
        );


    // ------------------------------------------------------------
    // Control hazard behavior
    // ------------------------------------------------------------

    // EX redirect must flush the younger instruction entering EX.
    ap_redirect_flush:
        assert property (@(posedge clk)
            disable iff (rst)
            ex_redirect |=> !id_ex_valid
        );

    // A redirect always reaches the PC, even when it coincides
    // with a load-use stall (redirect has priority over stall).
    ap_redirect_target:
        assert property (@(posedge clk)
            disable iff (rst)
            ex_redirect |=> (pc_current == $past(ex_redirect_pc))
        );


    // ------------------------------------------------------------
    // Precise traps
    // ------------------------------------------------------------

    // Trap entry always redirects to mtvec.
    ap_trap_target:
        assert property (@(posedge clk)
            disable iff (rst)
            trap_enter |-> (ex_redirect && (ex_redirect_pc == mtvec))
        );

    // The trapping instruction never reaches MEM, and neither does
    // any younger (wrong-path) instruction: the next instruction to
    // enter MEM is at the earliest the first handler instruction,
    // which needs three cycles (IF, ID, EX) after the redirect.
    ap_trap_no_younger_commit:
        assert property (@(posedge clk)
            disable iff (rst)
            // (Verilator lacks [*n] / ##n, so look back with $past.)
            ($past(trap_enter, 1) ||
             $past(trap_enter, 2) ||
             $past(trap_enter, 3)) |-> !ex_mem_valid
        );

    // Traps are only taken on a valid EX instruction, and mepc
    // captures that instruction's PC.
    ap_trap_on_valid:
        assert property (@(posedge clk)
            disable iff (rst)
            trap_enter |-> id_ex_valid
        );

    ap_trap_mepc:
        assert property (@(posedge clk)
            disable iff (rst)
            trap_enter |=> (mepc == $past(id_ex_pc))
        );


    // ------------------------------------------------------------
    // Interrupts
    // ------------------------------------------------------------

    // An interrupt is only taken when MIE, MTIE and MTIP are set.
    ap_irq_only_when_enabled:
        assert property (@(posedge clk)
            disable iff (rst)
            (trap_enter && trap_cause[31]) |->
                (global_irq_enable && timer_irq_enable && timer_irq_pending)
        );

    // An enabled, pending interrupt is never skipped at a valid
    // instruction boundary, and it wins over any exception there.
    ap_irq_not_missed:
        assert property (@(posedge clk)
            disable iff (rst)
            (id_ex_valid && global_irq_enable &&
             timer_irq_enable && timer_irq_pending) |->
                (trap_enter && (trap_cause == 32'h8000_0007))
        );

    // A committing MRET always redirects to mepc.
    ap_mret_target:
        assert property (@(posedge clk)
            disable iff (rst)
            (ex_take_mret && !trap_enter) |->
                (ex_redirect && (ex_redirect_pc == mepc))
        );

endmodule
