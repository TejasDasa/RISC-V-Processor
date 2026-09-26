// ============================================================
// Waveform probe.
//
// The only traced scope in the waveform builds (waves.vlt turns
// tracing off for the RTL). Core signals keep their core.sv
// names; a few derived signals are added purely for readability:
//
//   cycle          cycles since reset release
//   *_asm          disassembled instruction per stage (ASCII)
//   fwd_rs1_src    where EX's rs1 operand came from (ASCII)
//   fwd_rs2_src    where EX's rs2 operand came from (ASCII)
//
// Every cycle it also prints a PIPE line (IF/ID/EX/MEM/WB) to the
// simulation log, which the README cycle tables are taken from.
// ============================================================

`timescale 1ns / 1ps

module wave_probe
  import riscv_pkg::*;
  import rv_disasm_pkg::*;
(
    input logic        clk,
    input logic        rst,

    // IF
    input logic [31:0] pc_current,
    input logic        pc_we,
    input logic [31:0] if_instr,

    // IF/ID
    input logic        if_id_valid,
    input logic [31:0] if_id_pc,
    input logic [31:0] if_id_instr,

    // ID/EX
    input logic        id_ex_valid,
    input logic [31:0] id_ex_pc,
    input logic [31:0] id_ex_instr,
    input logic [4:0]  id_ex_rs1_addr,
    input logic [4:0]  id_ex_rs2_addr,
    input logic [4:0]  id_ex_rd_addr,
    input logic [31:0] id_ex_rs1_data,
    input logic [31:0] id_ex_rs2_data,
    input logic        id_ex_mem_read_en,
    input logic        id_ex_mem_write_en,

    // EX
    input logic [31:0] ex_rs1_forwarded,
    input logic [31:0] ex_rs2_forwarded,
    input logic [31:0] ex_alu_result,
    input logic        ex_branch_taken,
    input logic        ex_take_branch,
    input logic        ex_take_jump,
    input logic        ex_take_jalr,
    input logic        ex_take_mret,
    input logic        ex_redirect,
    input logic [31:0] ex_redirect_pc,
    input logic        load_use_hazard,

    // EX/MEM
    input logic        ex_mem_valid,
    input logic [31:0] ex_mem_pc,
    input logic [31:0] ex_mem_instr,
    input logic [4:0]  ex_mem_rd_addr,
    input logic        ex_mem_reg_write_en,
    input wb_sel_t     ex_mem_wb_sel,
    input logic [31:0] ex_mem_alu_result,
    input logic [31:0] ex_mem_rs2_data,
    input logic        ex_mem_trap,

    // Bus (MEM stage)
    input logic [31:0] bus_addr,
    input logic        bus_read_en,
    input logic        bus_write_en,
    input logic [31:0] bus_write_data,
    input logic [3:0]  bus_byte_en,
    input logic [31:0] bus_read_data,

    // MEM/WB
    input logic        mem_wb_valid,
    input logic [31:0] mem_wb_pc,
    input logic [31:0] mem_wb_instr,
    input logic [4:0]  mem_wb_rd_addr,
    input logic        mem_wb_reg_write_en,
    input logic        mem_wb_trap,

    // WB
    input logic [4:0]  wb_rd_addr,
    input logic [31:0] wb_data,
    input logic        wb_reg_write_en,

    // Retirement
    input logic        retire_valid,
    input logic [31:0] retire_pc,
    input logic        retire_exception,
    input logic        retire_interrupt,
    input logic [31:0] retire_cause,

    // Privileged
    input logic        cpu_irq,
    input logic        global_irq_enable,   // mstatus.MIE
    input logic        timer_irq_enable,    // mie.MTIE
    input logic        timer_irq_pending,   // mip.MTIP
    input logic        ex_irq,
    input logic        ex_exception,
    input logic        trap_enter,
    input logic [31:0] trap_cause,
    input logic [31:0] mstatus,
    input logic [31:0] mtvec,
    input logic [31:0] mepc,
    input logic [31:0] mcause,

    // SoC
    input logic [31:0] timer_count,
    input logic [31:0] timer_compare,
    input logic [31:0] gpio_out,

    // Selected architectural registers
    input logic [31:0] x1_ra,
    input logic [31:0] x2_sp,
    input logic [31:0] x10_a0
);

    // ------------------------------------------------------------
    // Cycle counter (0 = first cycle after reset release)
    // ------------------------------------------------------------

    int unsigned cycle;

    always_ff @(posedge clk) begin
        if (rst)
            cycle <= 0;
        else
            cycle <= cycle + 1;
    end

    // ------------------------------------------------------------
    // Per-stage disassembly
    // ------------------------------------------------------------

    function automatic string stage_asm(
        input logic        valid,
        input logic        trap,
        input logic [31:0] instr
    );
        if (valid)
            return rv_disasm(instr);
        if (trap)
            return {"TRAP ", rv_disasm(instr)};
        return "bubble";
    endfunction

    string if_s, id_s, ex_s, mem_s, wb_s;

    always_comb begin
        if_s  = rv_disasm(if_instr);
        id_s  = stage_asm(if_id_valid,  1'b0,        if_id_instr);
        ex_s  = stage_asm(id_ex_valid,  1'b0,        id_ex_instr);
        mem_s = stage_asm(ex_mem_valid, ex_mem_trap, ex_mem_instr);
        wb_s  = stage_asm(mem_wb_valid, mem_wb_trap, mem_wb_instr);
    end

    logic [8*ASM_CHARS-1:0] if_asm;
    logic [8*ASM_CHARS-1:0] id_asm;
    logic [8*ASM_CHARS-1:0] ex_asm;
    logic [8*ASM_CHARS-1:0] mem_asm;
    logic [8*ASM_CHARS-1:0] wb_asm;

    always @* begin
        $sformat(if_asm,  "%s", if_s);
        $sformat(id_asm,  "%s", id_s);
        $sformat(ex_asm,  "%s", ex_s);
        $sformat(mem_asm, "%s", mem_s);
        $sformat(wb_asm,  "%s", wb_s);
    end

    // ------------------------------------------------------------
    // Forwarding source (mirrors the core's forwarding priority:
    // EX/MEM over MEM/WB over the ID/EX register value)
    // ------------------------------------------------------------

    function automatic string fwd_src(input logic [4:0] rs);
        if (ex_mem_valid && ex_mem_reg_write_en &&
            (ex_mem_rd_addr != 5'd0) && (ex_mem_rd_addr == rs) &&
            (ex_mem_wb_sel != WB_MEM))
            return "EX/MEM";
        if (mem_wb_valid && mem_wb_reg_write_en &&
            (mem_wb_rd_addr != 5'd0) && (mem_wb_rd_addr == rs))
            return "MEM/WB";
        return "regfile";
    endfunction

    logic [8*8-1:0] fwd_rs1_src;
    logic [8*8-1:0] fwd_rs2_src;

    always @* begin
        $sformat(fwd_rs1_src, "%s",
                 id_ex_valid ? fwd_src(id_ex_rs1_addr) : "-");
        $sformat(fwd_rs2_src, "%s",
                 id_ex_valid ? fwd_src(id_ex_rs2_addr) : "-");
    end

    // ------------------------------------------------------------
    // Cycle table for the log
    // ------------------------------------------------------------

    always @(posedge clk) begin
        if (!rst) begin
            $display(
                "PIPE %4d | pc=%08h | IF %-20s | ID %-20s | EX %-20s | MEM %-24s | WB %-24s |%s%s%s%s%s",
                cycle, pc_current, if_s, id_s, ex_s, mem_s, wb_s,
                load_use_hazard ? " STALL"                       : "",
                ex_redirect     ? $sformatf(" REDIRECT->%08h",
                                            ex_redirect_pc)      : "",
                ex_irq          ? " IRQ"                         : "",
                trap_enter      ? " TRAP"                        : "",
                wb_reg_write_en ? $sformatf(" WB x%0d=%08h",
                                            wb_rd_addr, wb_data) : ""
            );
        end
    end

endmodule
