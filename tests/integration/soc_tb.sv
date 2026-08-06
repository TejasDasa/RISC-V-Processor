module soc_tb;

  localparam int UART_CLOCK_HZ  = 10;
  localparam int UART_BAUD_RATE = 2;
  localparam int CLKS_PER_BIT   = UART_CLOCK_HZ / UART_BAUD_RATE;

  logic clk;
  logic rst;

  logic [31:0] debug_pc;
  logic [31:0] debug_instr;

  logic uart_tx;
  logic uart_busy;

  int failures;

  soc #(
      .IMEM_INIT_FILE(""),
      .DMEM_INIT_FILE(""),
      .UART_CLOCK_HZ(UART_CLOCK_HZ),
      .UART_BAUD_RATE(UART_BAUD_RATE)
  ) dut (
      .clk         (clk),
      .rst         (rst),
      .debug_pc    (debug_pc),
      .debug_instr (debug_instr),
      .uart_tx     (uart_tx),
      .uart_busy   (uart_busy)
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

  task automatic check_eq8(
      input string test_name,
      input logic [7:0] actual,
      input logic [7:0] expected
  );
    if (actual !== expected) begin
      $error(
          "%s failed: expected 0x%02h, got 0x%02h",
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

  task automatic receive_uart_byte(
      output logic [7:0] received_byte
  );
    received_byte = 8'h00;

    // Wait for falling edge marking the start bit.
    @(negedge uart_tx);

    // Move to the middle of the start bit.
    wait_clocks(CLKS_PER_BIT / 2);

    if (uart_tx !== 1'b0) begin
      $error("UART start bit was not low");
      failures++;
    end

    // Move from middle of start bit to middle of data bit 0.
    wait_clocks(CLKS_PER_BIT);

    for (int bit_index = 0; bit_index < 8; bit_index++) begin
      received_byte[bit_index] = uart_tx;
      wait_clocks(CLKS_PER_BIT);
    end

    // We are now at the middle of the stop bit.
    if (uart_tx !== 1'b1) begin
      $error("UART stop bit was not high");
      failures++;
    end
  endtask

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    logic [7:0] received_byte;

    failures = 0;
    rst      = 1'b1;

    /*
     * 0x00: lui  x1, 0x10000
     * 0x04: addi x2, x0, 72
     * 0x08: sb   x2, 0(x1)
     * 0x0c: jal  x0, 0
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

    // Wait for and decode one serialized UART frame.
    receive_uart_byte(received_byte);

    check_eq8(
        "serialized UART byte",
        received_byte,
        8'h48
    );

    // Allow the UART to finish and return to idle.
    wait_clocks(CLKS_PER_BIT + 2);

    if (uart_busy !== 1'b0) begin
      $error("UART remained busy after frame completion");
      failures++;
    end

    if (uart_tx !== 1'b1) begin
      $error("UART TX line did not return to idle high");
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

    check_eq32(
        "halt-loop PC",
        debug_pc,
        32'h0000_000c
    );

    if (failures == 0) begin
      $display(
          "PASS: SoC serialized UART byte 0x%02h '%c'",
          received_byte,
          received_byte
      );
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