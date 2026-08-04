module soc_tb;

  logic clk;
  logic rst;

  logic [31:0] debug_pc;
  logic [31:0] debug_instr;

  logic       uart_tx_valid;
  logic [7:0] uart_tx_data;

  int failures;
  int uart_write_count;

  soc #(
      .IMEM_INIT_FILE(""),
      .DMEM_INIT_FILE("")
  ) dut (
      .clk           (clk),
      .rst           (rst),

      .debug_pc      (debug_pc),
      .debug_instr   (debug_instr),

      .uart_tx_valid (uart_tx_valid),
      .uart_tx_data  (uart_tx_data)
  );

  task automatic check_eq32(
      input string test_name,
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

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  always_ff @(posedge clk) begin
    if (!rst && uart_tx_valid) begin
      uart_write_count++;

      if (uart_tx_data !== 8'h48) begin
        $error(
            "UART data failed: expected 0x48, got 0x%02h",
            uart_tx_data
        );
        failures++;
      end

      $display(
          "UART_TX 0x%02h '%c'",
          uart_tx_data,
          uart_tx_data
      );
    end
  end

  initial begin
    failures        = 0;
    uart_write_count = 0;
    rst             = 1'b1;

    /*
     * Program:
     *
     * 0x00: lui  x1, 0x10000
     *       x1 = 0x10000000
     *
     * 0x04: addi x2, x0, 72
     *       x2 = ASCII 'H'
     *
     * 0x08: sb   x2, 0(x1)
     *
     * 0x0c: jal  x0, 0
     *       infinite loop
     */

    dut.core_inst.imem_inst.mem[0] = 32'h1000_00B7;
    dut.core_inst.imem_inst.mem[1] = 32'h0480_0113;
    dut.core_inst.imem_inst.mem[2] = 32'h0020_8023;
    dut.core_inst.imem_inst.mem[3] = 32'h0000_006F;

    @(posedge clk);
    #1;

    check_eq32(
        "reset PC",
        debug_pc,
        32'h0000_0000
    );

    rst = 1'b0;

    repeat (12) begin
      @(posedge clk);
      #1;
    end

    if (uart_write_count !== 1) begin
      $error(
          "UART write count failed: expected 1, got %0d",
          uart_write_count
      );
      failures++;
    end

    check_eq32(
        "UART address register x1",
        dut.core_inst.regfile_inst.regs[1],
        32'h1000_0000
    );

    check_eq32(
        "UART character register x2",
        dut.core_inst.regfile_inst.regs[2],
        32'd72
    );

    // The final JAL loops at address 0x0c.
    check_eq32(
        "halt-loop PC",
        debug_pc,
        32'h0000_000c
    );

    if (failures == 0) begin
      $display("PASS: SoC routed CPU store to UART");
    end else begin
      $fatal(
          1,
          "FAIL: soc_tb had %0d failure(s)",
          failures
      );
    end

    $finish;
  end

endmodule
