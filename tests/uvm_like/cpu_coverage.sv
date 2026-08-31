module cpu_coverage (
    input logic clk,
    input logic rst,

    // Pipeline state
    input logic        id_ex_valid,
    input logic [4:0]  id_ex_rs1_addr,
    input logic [4:0]  id_ex_rs2_addr,
    input logic [4:0] id_ex_rd_addr,

    input logic        ex_mem_valid,
    input logic        ex_mem_reg_write_en,
    input logic [4:0]  ex_mem_rd_addr,

    input logic        mem_wb_valid,
    input logic        mem_wb_reg_write_en,
    input logic [4:0]  mem_wb_rd_addr,

    // Hazard/control events
    input logic load_use_hazard,
    input logic ex_branch_taken,
    input logic ex_take_branch,
    input logic ex_take_jump,
    input logic ex_take_jalr,
    input logic ex_redirect,

    // Memory behavior
    input logic id_ex_mem_read_en,
    input logic id_ex_mem_write_en,

    // Retirement
    input logic retire_valid
);

    // ============================================================
    // Derived events
    // ============================================================

    logic exmem_rs1_forward;
    logic exmem_rs2_forward;

    logic memwb_rs1_forward;
    logic memwb_rs2_forward;

    assign exmem_rs1_forward =
        id_ex_valid &&
        ex_mem_valid &&
        ex_mem_reg_write_en &&
        (ex_mem_rd_addr != 5'd0) &&
        (ex_mem_rd_addr == id_ex_rs1_addr);

    assign exmem_rs2_forward =
        id_ex_valid &&
        ex_mem_valid &&
        ex_mem_reg_write_en &&
        (ex_mem_rd_addr != 5'd0) &&
        (ex_mem_rd_addr == id_ex_rs2_addr);

    assign memwb_rs1_forward =
        id_ex_valid &&
        mem_wb_valid &&
        mem_wb_reg_write_en &&
        (mem_wb_rd_addr != 5'd0) &&
        (mem_wb_rd_addr == id_ex_rs1_addr);

    assign memwb_rs2_forward =
        id_ex_valid &&
        mem_wb_valid &&
        mem_wb_reg_write_en &&
        (mem_wb_rd_addr != 5'd0) &&
        (mem_wb_rd_addr == id_ex_rs2_addr);


    // ============================================================
    // Counters
    // ============================================================

    int unsigned count_exmem_rs1;
    int unsigned count_exmem_rs2;

    int unsigned count_memwb_rs1;
    int unsigned count_memwb_rs2;

    int unsigned count_load_use;

    int unsigned count_branch_taken;
    int unsigned count_branch_not_taken;

    int unsigned count_jal;
    int unsigned count_jalr;

    int unsigned count_redirect;

    int unsigned count_load;
    int unsigned count_store;

    int unsigned count_retire;

    logic meaningful_jal;


    always_ff @(posedge clk) begin
        if (rst) begin
            count_exmem_rs1        <= 0;
            count_exmem_rs2        <= 0;

            count_memwb_rs1        <= 0;
            count_memwb_rs2        <= 0;

            count_load_use         <= 0;

            count_branch_taken     <= 0;
            count_branch_not_taken <= 0;

            count_jal              <= 0;
            count_jalr             <= 0;

            count_redirect         <= 0;

            count_load             <= 0;
            count_store            <= 0;

            count_retire           <= 0;
        end
        else begin

            if (exmem_rs1_forward)
                count_exmem_rs1 <= count_exmem_rs1 + 1;

            if (exmem_rs2_forward)
                count_exmem_rs2 <= count_exmem_rs2 + 1;

            if (memwb_rs1_forward)
                count_memwb_rs1 <= count_memwb_rs1 + 1;

            if (memwb_rs2_forward)
                count_memwb_rs2 <= count_memwb_rs2 + 1;

            if (load_use_hazard)
                count_load_use <= count_load_use + 1;

            if (ex_take_branch)
                count_branch_taken <= count_branch_taken + 1;

            if (
                id_ex_valid &&
                !ex_branch_taken &&
                !ex_take_jump &&
                !ex_take_jalr
            )
                count_branch_not_taken <=
                    count_branch_not_taken + 1;

            if (ex_take_jump)
                count_jal <= count_jal + 1;

            assign meaningful_jal =
                ex_take_jump &&
                (id_ex_rd_addr != 5'd0);

            if (meaningful_jal)
                count_jalr <= count_jalr + 1;

            if (ex_redirect)
                count_redirect <= count_redirect + 1;

            if (
                id_ex_valid &&
                id_ex_mem_read_en
            )
                count_load <= count_load + 1;

            if (
                id_ex_valid &&
                id_ex_mem_write_en
            )
                count_store <= count_store + 1;

            if (retire_valid)
                count_retire <= count_retire + 1;
        end
    end


    // ============================================================
    // Summary
    // ============================================================

    final begin
        $display("");
        $display("========================================");
        $display(" PIPELINE COVERAGE SUMMARY");
        $display("========================================");

        $display(
            "EX/MEM -> rs1 forwarding : %0d",
            count_exmem_rs1
        );

        $display(
            "EX/MEM -> rs2 forwarding : %0d",
            count_exmem_rs2
        );

        $display(
            "MEM/WB -> rs1 forwarding : %0d",
            count_memwb_rs1
        );

        $display(
            "MEM/WB -> rs2 forwarding : %0d",
            count_memwb_rs2
        );

        $display(
            "Load-use stalls          : %0d",
            count_load_use
        );

        $display(
            "Taken branches           : %0d",
            count_branch_taken
        );

        $display(
            "Not-taken branch-ish     : %0d",
            count_branch_not_taken
        );

        $display(
            "JAL redirects            : %0d",
            count_jal
        );

        $display(
            "JALR redirects           : %0d",
            count_jalr
        );

        $display(
            "All redirects            : %0d",
            count_redirect
        );

        $display(
            "Loads                    : %0d",
            count_load
        );

        $display(
            "Stores                   : %0d",
            count_store
        );

        $display(
            "Retired instructions     : %0d",
            count_retire
        );

        $display("========================================");
    end

endmodule