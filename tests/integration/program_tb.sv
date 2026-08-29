module program_tb #(
    parameter string PROGRAM_HEX =
        "software/build/add_imem.hex",

    parameter string PROGRAM_DMEM_HEX =
        "software/build/add_dmem.hex",

    parameter int RUN_CYCLES = 10000
);

    logic clk;
    logic rst;

    logic [31:0] debug_pc;
    logic [31:0] debug_instr;

    logic        soc_uart_valid;
    logic [7:0]  soc_uart_data;
    logic        soc_uart_busy;

    logic        cpu_irq;
    logic [31:0] gpio_out;

    int failures;

    byte uart_bytes[$];


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

        .uart_write_valid   (soc_uart_valid),
        .uart_write_data    (soc_uart_data),
        .uart_external_busy (soc_uart_busy),

        .cpu_irq            (cpu_irq),
        .gpio_out           (gpio_out)
    );


    // CPU Monitor inst
    cpu_monitor monitor (
        .clk              (clk),
        .rst              (rst),

        .retire_valid     (dut.core_inst.retire_valid),
        .retire_pc        (dut.core_inst.retire_pc),
        .retire_instr     (dut.core_inst.retire_instr),

        .retire_reg_write (dut.core_inst.retire_reg_write),
        .retire_rd        (dut.core_inst.retire_rd),
        .retire_rd_data   (dut.core_inst.retire_rd_data)
    );

    // Assertions inst
    cpu_assertions assertions (
        .clk             (clk),
        .rst             (rst),

        .load_use_hazard (dut.core_inst.load_use_hazard),
        .ex_redirect     (dut.core_inst.ex_redirect),

        .pc_current      (dut.core_inst.pc_current),

        .id_ex_valid     (dut.core_inst.id_ex_valid),
        .ex_mem_valid    (dut.core_inst.ex_mem_valid),
        .mem_wb_valid    (dut.core_inst.mem_wb_valid),

        .bus_read_en     (dut.core_inst.bus_read_en),
        .bus_write_en    (dut.core_inst.bus_write_en),

        .wb_reg_write_en (dut.core_inst.wb_reg_write_en),
        .wb_rd_addr      (dut.core_inst.wb_rd_addr),

        .x0              (dut.core_inst.regfile_inst.regs[0])
    );


    // ============================================================
    // CLOCK
    // ============================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // ============================================================
    // HELPERS
    // ============================================================

    task automatic check_eq32(
        input string       test_name,
        input logic [31:0] actual,
        input logic [31:0] expected
    );
        if (actual !== expected) begin
            $error(
                "%s failed: expected 0x%08h, got 0x%08h",
                test_name,
                expected,
                actual
            );

            failures++;
        end
    endtask


    task automatic wait_clocks(
        input int count
    );
        repeat (count) begin
            @(posedge clk);
            #1;
        end
    endtask


    // ============================================================
    // BYTE-LEVEL UART MODEL
    //
    // The SoC exposes:
    //
    //   uart_write_valid
    //   uart_write_data
    //   uart_external_busy
    //
    // This testbench behaves like the external UART/mailbox
    // consumer. A byte is captured whenever VALID is asserted
    // while BUSY is low.
    // ============================================================

    always_ff @(posedge clk) begin
        if (rst) begin
            soc_uart_busy <= 1'b0;
        end else begin

            /*
             * Default: ready to accept another byte.
             */
            soc_uart_busy <= 1'b0;

            if (soc_uart_valid && !soc_uart_busy) begin

                uart_bytes.push_back(soc_uart_data);

                $display(
                    "UART_RX 0x%02h '%c'",
                    soc_uart_data,
                    soc_uart_data
                );

                /*
                 * Hold busy for one cycle so software does not
                 * immediately issue another write in the same
                 * transaction window.
                 */
                soc_uart_busy <= 1'b1;
            end
        end
    end


    // ============================================================
    // OPTIONAL PIPELINE / BUS TRACE
    //
    // Useful while bringing up hazards.
    // Comment this block out once the pipeline is stable.
    // ============================================================



    always @(posedge clk) begin
        if (!rst) begin
            $display("PC=%08h | ID_EX v=%b pc=%08h rs1=x%0d raw=%08h fwd=%08h imm=%08h | EX=%08h | EX_MEM v=%b addr=%08h read=%b write=%b",
                dut.core_inst.pc_current,
                dut.core_inst.id_ex_valid,
                dut.core_inst.id_ex_pc,
                dut.core_inst.id_ex_rs1_addr,
                dut.core_inst.id_ex_rs1_data,
                dut.core_inst.ex_rs1_forwarded,
                dut.core_inst.id_ex_imm,
                dut.core_inst.ex_alu_result,
                dut.core_inst.ex_mem_valid,
                dut.core_inst.ex_mem_alu_result,
                dut.core_inst.ex_mem_mem_read_en,
                dut.core_inst.ex_mem_mem_write_en
            );
        end
    end




    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        failures      = 0;
        rst           = 1'b1;
        soc_uart_busy = 1'b0;

        /*
         * Hold reset for a few clocks so every pipeline stage
         * definitely sees reset.
         */
        wait_clocks(3);

        check_eq32(
            "reset PC",
            debug_pc,
            32'd0
        );

        rst = 1'b0;

        /*
         * Let the program execute.
         */
        wait_clocks(RUN_CYCLES);


        // ========================================================
        // REGISTER DUMP
        // ========================================================

        for (int i = 0; i < 32; i++) begin
            $display(
                "REG x%0d = 0x%08h (%0d)",
                i,
                dut.core_inst.regfile_inst.regs[i],
                dut.core_inst.regfile_inst.regs[i]
            );
        end

        // MEM DUMP
        for (int i = 0; i < 64; i++) begin
            $display(
                "MEM 0x%08h = 0x%08h",
                32'h0001_0000 + (i * 4),
                dut.bus_inst.dmem_inst.mem[i]
            );
        end


        // ========================================================
        // UART DUMP
        // ========================================================

        $display(
            "UART byte count: %0d",
            uart_bytes.size()
        );

        if (uart_bytes.size() > 0) begin

            $write("UART text: ");

            foreach (uart_bytes[i]) begin
                $write("%c", uart_bytes[i]);
            end

            $write("\n");
        end


        // ========================================================
        // RESULT
        // ========================================================

        if (failures == 0) begin
            $display(
                "PASS: program executed without testbench failures"
            );
        end else begin
            $fatal(
                1,
                "FAIL: program_tb had %0d failure(s)",
                failures
            );
        end

        $finish;
    end

endmodule