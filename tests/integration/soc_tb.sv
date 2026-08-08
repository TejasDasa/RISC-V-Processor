module soc_tb;

  logic clk;
  logic rst;

  logic [31:0] debug_pc;
  logic [31:0] debug_instr;

  logic uart_tx;
  logic uart_busy;
  logic cpu_irq;

  int failures;

  soc #(
      .IMEM_INIT_FILE(""),
      .DMEM_INIT_FILE(""),
      .UART_CLOCK_HZ(10),
      .UART_BAUD_RATE(2)
  ) dut (
      .clk         (clk),
      .rst         (rst),

      .debug_pc    (debug_pc),
      .debug_instr (debug_instr),

      .uart_tx     (uart_tx),
      .uart_busy   (uart_busy),

      .cpu_irq     (cpu_irq)
  );

  task automatic check_eq1(
      input string test_name,
      input logic actual,
      input logic expected
  );
    if (actual !== expected) begin
      $error(
          "%s failed: expected %0b, got %0b",
          test_name,
          expected,
          actual
      );
      failures++;
    end
  endtask

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

  task automatic wait_clocks(input int count);
    repeat (count) begin
      @(posedge clk);
      #1;
    end
  endtask

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    failures = 0;
    rst      = 1'b1;

    /*
     * Program:
     *
     * 0x00: lui  x1, 0x10000
     *       x1 = 0x1000_0000
     *
     * 0x04: addi x2, x0, 5
     *       x2 = compare value
     *
     * 0x08: sw   x2, 20(x1)
     *       TIMER_COMPARE = 5
     *
     * 0x0c: addi x2, x0, 3
     *       bit 0 = timer enable
     *       bit 1 = interrupt enable
     *
     * 0x10: sw   x2, 24(x1)
     *       TIMER_CONTROL = 3
     *
     * 0x14: jal  x0, 0
     *       infinite loop
     */

    dut.core_inst.imem_inst.mem[0] = 32'h1000_00B7;
    dut.core_inst.imem_inst.mem[1] = 32'h0050_0113;
    dut.core_inst.imem_inst.mem[2] = 32'h0020_AA23;
    dut.core_inst.imem_inst.mem[3] = 32'h0030_0113;
    dut.core_inst.imem_inst.mem[4] = 32'h0020_AC23;
    dut.core_inst.imem_inst.mem[5] = 32'h0000_006F;

    // ----------------------------------------------------------
    // Reset
    // ----------------------------------------------------------

    @(posedge clk);
    #1;

    check_eq32(
        "reset PC",
        debug_pc,
        32'h0000_0000
    );

    check_eq1(
        "CPU IRQ low during reset",
        cpu_irq,
        1'b0
    );

    check_eq32(
        "timer count after reset",
        dut.timer_inst.counter,
        32'd0
    );

    check_eq32(
        "timer compare after reset",
        dut.timer_inst.compare,
        32'd0
    );

    check_eq32(
        "timer control after reset",
        dut.timer_inst.control,
        32'd0
    );

    rst = 1'b0;

    // ----------------------------------------------------------
    // CPU programs timer through the bus
    // ----------------------------------------------------------

    wait_clocks(6);

    check_eq32(
        "timer compare programmed through bus",
        dut.timer_inst.compare,
        32'd5
    );

    check_eq32(
        "timer control programmed through bus",
        dut.timer_inst.control,
        32'd3
    );

    check_eq1(
        "CPU IRQ low before compare",
        cpu_irq,
        1'b0
    );

    // ----------------------------------------------------------
    // Wait for timer interrupt
    // ----------------------------------------------------------

    while (dut.timer_inst.counter < dut.timer_inst.compare) begin
      @(posedge clk);
      #1;
    end

    check_eq32(
        "timer counter reached compare",
        dut.timer_inst.counter,
        32'd5
    );

    check_eq1(
        "CPU IRQ asserted",
        cpu_irq,
        1'b1
    );

    // ----------------------------------------------------------
    // Verify level-sensitive IRQ remains asserted
    // ----------------------------------------------------------

    wait_clocks(3);

    check_eq1(
        "CPU IRQ remains asserted",
        cpu_irq,
        1'b1
    );

    if (dut.timer_inst.counter < 32'd8) begin
      $error(
          "Timer counter did not continue after IRQ: got %0d",
          dut.timer_inst.counter
      );
      failures++;
    end

    // ----------------------------------------------------------
    // Check CPU state
    // ----------------------------------------------------------

    check_eq32(
        "timer base register x1",
        dut.core_inst.regfile_inst.regs[1],
        32'h1000_0000
    );

    check_eq32(
        "timer control value register x2",
        dut.core_inst.regfile_inst.regs[2],
        32'd3
    );

    check_eq32(
        "halt-loop PC",
        debug_pc,
        32'h0000_0014
    );

    // ----------------------------------------------------------
    // Results
    // ----------------------------------------------------------

    if (failures == 0) begin
      $display(
          "PASS: Timer IRQ propagated through interrupt controller to CPU IRQ"
      );
    end else begin
      $fatal(
          1,
          "FAIL: soc_timer_irq_tb had %0d failure(s)",
          failures
      );
    end

    $finish;
  end

endmodule
