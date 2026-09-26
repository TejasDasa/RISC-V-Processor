// ============================================================
// Waveform demo testbench.
//
// Runs one short program on the real SoC (soc -> core) and dumps
// only the wave_probe scope to a VCD (or FST) file. The run stops
// DRAIN_CYCLES after the program's halt instruction ("j .",
// 0x0000006f) retires, so each waveform ends right after the
// interesting event instead of spinning in the halt loop.
//
// The register dump at the end is checked against the demo's
// .expected file, so every waveform is also a self-checking test.
// ============================================================

`timescale 1ns / 1ps

module wave_tb #(
    parameter string PROGRAM_HEX      = "",
    parameter string PROGRAM_DMEM_HEX = "",
    parameter string WAVE_FILE        = "waves/wave.vcd",
    parameter int    MAX_CYCLES       = 5000,
    parameter int    DRAIN_CYCLES     = 4,

    // Start dumping only when the first MRET reaches EX (skips
    // C-runtime startup in the scheduler demo).
    parameter bit    DUMP_START_ON_MRET = 1'b0
);

    logic clk;
    logic rst;

    logic [31:0] debug_pc;
    logic [31:0] debug_instr;
    logic        uart_valid;
    logic [7:0]  uart_data;
    logic        cpu_irq;
    logic [31:0] gpio_out;

    // ============================================================
    // DUT
    // ============================================================

    soc #(
        .IMEM_INIT_FILE (PROGRAM_HEX),
        .DMEM_INIT_FILE (PROGRAM_DMEM_HEX)
    ) dut (
        .clk                (clk),
        .rst                (rst),
        .debug_pc           (debug_pc),
        .debug_instr        (debug_instr),
        .uart_write_valid   (uart_valid),
        .uart_write_data    (uart_data),
        .uart_external_busy (1'b0),
        .cpu_irq            (cpu_irq),
        .gpio_out           (gpio_out)
    );

    // ============================================================
    // Probe (the traced scope)
    // ============================================================

    wave_probe cpu (
        .clk                 (clk),
        .rst                 (rst),

        .pc_current          (dut.core_inst.pc_current),
        .pc_we               (dut.core_inst.pc_we),
        .if_instr            (dut.core_inst.if_instr),

        .if_id_valid         (dut.core_inst.if_id_valid),
        .if_id_pc            (dut.core_inst.if_id_pc),
        .if_id_instr         (dut.core_inst.if_id_instr),

        .id_ex_valid         (dut.core_inst.id_ex_valid),
        .id_ex_pc            (dut.core_inst.id_ex_pc),
        .id_ex_instr         (dut.core_inst.id_ex_instr),
        .id_ex_rs1_addr      (dut.core_inst.id_ex_rs1_addr),
        .id_ex_rs2_addr      (dut.core_inst.id_ex_rs2_addr),
        .id_ex_rd_addr       (dut.core_inst.id_ex_rd_addr),
        .id_ex_rs1_data      (dut.core_inst.id_ex_rs1_data),
        .id_ex_rs2_data      (dut.core_inst.id_ex_rs2_data),
        .id_ex_mem_read_en   (dut.core_inst.id_ex_mem_read_en),
        .id_ex_mem_write_en  (dut.core_inst.id_ex_mem_write_en),

        .ex_rs1_forwarded    (dut.core_inst.ex_rs1_forwarded),
        .ex_rs2_forwarded    (dut.core_inst.ex_rs2_forwarded),
        .ex_alu_result       (dut.core_inst.ex_alu_result),
        .ex_branch_taken     (dut.core_inst.ex_branch_taken),
        .ex_take_branch      (dut.core_inst.ex_take_branch),
        .ex_take_jump        (dut.core_inst.ex_take_jump),
        .ex_take_jalr        (dut.core_inst.ex_take_jalr),
        .ex_take_mret        (dut.core_inst.ex_take_mret),
        .ex_redirect         (dut.core_inst.ex_redirect),
        .ex_redirect_pc      (dut.core_inst.ex_redirect_pc),
        .load_use_hazard     (dut.core_inst.load_use_hazard),

        .ex_mem_valid        (dut.core_inst.ex_mem_valid),
        .ex_mem_pc           (dut.core_inst.ex_mem_pc),
        .ex_mem_instr        (dut.core_inst.ex_mem_instr),
        .ex_mem_rd_addr      (dut.core_inst.ex_mem_rd_addr),
        .ex_mem_reg_write_en (dut.core_inst.ex_mem_reg_write_en),
        .ex_mem_wb_sel       (dut.core_inst.ex_mem_wb_sel),
        .ex_mem_alu_result   (dut.core_inst.ex_mem_alu_result),
        .ex_mem_rs2_data     (dut.core_inst.ex_mem_rs2_data),
        .ex_mem_trap         (dut.core_inst.ex_mem_trap),

        .bus_addr            (dut.core_inst.bus_addr),
        .bus_read_en         (dut.core_inst.bus_read_en),
        .bus_write_en        (dut.core_inst.bus_write_en),
        .bus_write_data      (dut.core_inst.bus_write_data),
        .bus_byte_en         (dut.core_inst.bus_byte_en),
        .bus_read_data       (dut.core_inst.bus_read_data),

        .mem_wb_valid        (dut.core_inst.mem_wb_valid),
        .mem_wb_pc           (dut.core_inst.mem_wb_pc),
        .mem_wb_instr        (dut.core_inst.mem_wb_instr),
        .mem_wb_rd_addr      (dut.core_inst.mem_wb_rd_addr),
        .mem_wb_reg_write_en (dut.core_inst.mem_wb_reg_write_en),
        .mem_wb_trap         (dut.core_inst.mem_wb_trap),

        .wb_rd_addr          (dut.core_inst.wb_rd_addr),
        .wb_data             (dut.core_inst.wb_data),
        .wb_reg_write_en     (dut.core_inst.wb_reg_write_en),

        .retire_valid        (dut.core_inst.retire_valid),
        .retire_pc           (dut.core_inst.retire_pc),
        .retire_exception    (dut.core_inst.retire_exception),
        .retire_interrupt    (dut.core_inst.retire_interrupt),
        .retire_cause        (dut.core_inst.retire_cause),

        .cpu_irq             (cpu_irq),
        .global_irq_enable   (dut.core_inst.global_irq_enable),
        .timer_irq_enable    (dut.core_inst.timer_irq_enable),
        .timer_irq_pending   (dut.core_inst.timer_irq_pending),
        .ex_irq              (dut.core_inst.ex_irq),
        .ex_exception        (dut.core_inst.ex_exception),
        .trap_enter          (dut.core_inst.trap_enter),
        .trap_cause          (dut.core_inst.trap_cause),
        .mstatus             (dut.core_inst.csr_file_inst.mstatus),
        .mtvec               (dut.core_inst.mtvec),
        .mepc                (dut.core_inst.mepc),
        .mcause              (dut.core_inst.csr_file_inst.mcause),

        .timer_count         (dut.timer_count),
        .timer_compare       (dut.timer_compare),
        .gpio_out            (gpio_out),

        .x1_ra               (dut.core_inst.regfile_inst.regs[1]),
        .x2_sp               (dut.core_inst.regfile_inst.regs[2]),
        .x10_a0              (dut.core_inst.regfile_inst.regs[10])
    );

    // ============================================================
    // Pipeline assertions (same checks as the regression flow)
    // ============================================================

    cpu_assertions assertions (
        .clk               (clk),
        .rst               (rst),
        .load_use_hazard   (dut.core_inst.load_use_hazard),
        .ex_redirect       (dut.core_inst.ex_redirect),
        .ex_redirect_pc    (dut.core_inst.ex_redirect_pc),
        .trap_enter        (dut.core_inst.trap_enter),
        .mtvec             (dut.core_inst.mtvec),
        .ex_take_mret      (dut.core_inst.ex_take_mret),
        .mepc              (dut.core_inst.mepc),
        .trap_cause        (dut.core_inst.trap_cause),
        .global_irq_enable (dut.core_inst.global_irq_enable),
        .timer_irq_enable  (dut.core_inst.timer_irq_enable),
        .timer_irq_pending (dut.core_inst.timer_irq_pending),
        .pc_current        (dut.core_inst.pc_current),
        .id_ex_valid       (dut.core_inst.id_ex_valid),
        .id_ex_pc          (dut.core_inst.id_ex_pc),
        .ex_mem_valid      (dut.core_inst.ex_mem_valid),
        .mem_wb_valid      (dut.core_inst.mem_wb_valid),
        .bus_read_en       (dut.core_inst.bus_read_en),
        .bus_write_en      (dut.core_inst.bus_write_en),
        .wb_reg_write_en   (dut.core_inst.wb_reg_write_en),
        .wb_rd_addr        (dut.core_inst.wb_rd_addr),
        .x0                (dut.core_inst.regfile_inst.regs[0]),
        .retire_valid      (dut.core_inst.retire_valid),
        .retire_pc         (dut.core_inst.retire_pc),
        .retire_instr      (dut.core_inst.retire_instr),
        .retire_exception  (dut.core_inst.retire_exception),
        .retire_interrupt  (dut.core_inst.retire_interrupt),
        .retire_cause      (dut.core_inst.retire_cause)
    );

    // ============================================================
    // Clock: 10 ns period (100 MHz)
    // ============================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ============================================================
    // Run control
    // ============================================================

    logic halt_seen;
    int   drain;

    always_ff @(posedge clk) begin
        if (rst) begin
            halt_seen <= 1'b0;
            drain     <= 0;
        end
        else begin
            if (dut.core_inst.retire_valid &&
                dut.core_inst.retire_instr == 32'h0000_006f)
                halt_seen <= 1'b1;

            if (halt_seen)
                drain <= drain + 1;
        end
    end

    // Declared at module level so the loops add no extra scopes to
    // the waveform.
    int run_c;
    int reg_i;

    initial begin
        if (DUMP_START_ON_MRET)
            wait (!rst && dut.core_inst.ex_take_mret);

        $dumpfile(WAVE_FILE);
        $dumpvars(0, wave_tb);
    end

    initial begin
        rst = 1'b1;
        repeat (3) @(posedge clk);
        #1 rst = 1'b0;

        for (run_c = 0; run_c < MAX_CYCLES; run_c++) begin
            @(posedge clk);
            #1;
            if (halt_seen && drain >= DRAIN_CYCLES)
                break;
        end

        if (!halt_seen)
            $display("ERROR: program did not halt within %0d cycles",
                     MAX_CYCLES);

        for (reg_i = 0; reg_i < 32; reg_i++)
            $display("REG x%0d = 0x%08h (%0d)", reg_i,
                     dut.core_inst.regfile_inst.regs[reg_i],
                     dut.core_inst.regfile_inst.regs[reg_i]);

        $display("WAVE %s (%0d cycles)", WAVE_FILE, cpu.cycle);
        $finish;
    end

endmodule
