module cpu_assertions (
    input logic clk,
    input logic rst,

    input logic        load_use_hazard,
    input logic        ex_redirect,

    input logic [31:0] pc_current,

    input logic        id_ex_valid,
    input logic        ex_mem_valid,
    input logic        mem_wb_valid,

    input logic        bus_read_en,
    input logic        bus_write_en,

    input logic        wb_reg_write_en,
    input logic [4:0]  wb_rd_addr,

    input logic [31:0] x0
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

    // A load-use hazard must freeze the PC.
    ap_load_use_pc_stall:
        assert property (@(posedge clk)
            disable iff (rst)
            load_use_hazard |=> $stable(pc_current)
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

endmodule
