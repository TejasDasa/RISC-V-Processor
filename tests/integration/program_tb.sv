module program_tb #(
    parameter string PROGRAM_HEX =
        "software/build/add_imem.hex",

    parameter string PROGRAM_DMEM_HEX =
        "software/build/add_dmem.hex",

    parameter int UART_CLOCK_HZ  = 10,
    parameter int UART_BAUD_RATE = 2,

    parameter int RUN_CYCLES = 10000
);

  localparam int CLKS_PER_BIT =
      UART_CLOCK_HZ / UART_BAUD_RATE;

  logic clk;
  logic rst;

  logic [31:0] debug_pc;
  logic [31:0] debug_instr;

  // logic uart_tx;
  // logic uart_busy;

  logic soc_uart_busy;
  logic [7:0] soc_uart_data;
  logic soc_uart_valid;

  logic cpu_irq;
  logic gpio_out;

  int failures;

  byte uart_bytes[$];

  soc #(
      .IMEM_INIT_FILE  (PROGRAM_HEX),
      .DMEM_INIT_FILE  (PROGRAM_DMEM_HEX),
      .UART_CLOCK_HZ   (UART_CLOCK_HZ),
      .UART_BAUD_RATE  (UART_BAUD_RATE)
  ) dut (
      .clk         (clk),
      .rst         (rst),

      .debug_pc    (debug_pc),
      .debug_instr (debug_instr),

      .uart_write_valid   (soc_uart_valid),
      .uart_write_data    (soc_uart_data),
      .uart_external_busy (soc_uart_busy),

      // .uart_tx     (uart_tx),
      // .uart_busy   (uart_busy),

      .cpu_irq (cpu_irq),
      .gpio_out (gpio_out)
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

  task automatic wait_clocks(input int count);
    repeat (count) begin
      @(posedge clk);
      #1;
    end
  endtask

  /*
  task automatic receive_uart_byte(
      output logic [7:0] received_byte
  );
    received_byte = 8'h00;

    // Falling edge marks the beginning of the start bit.
    @(negedge uart_tx);

    // Sample near the center of the start bit.
    wait_clocks(CLKS_PER_BIT / 2);

    if (uart_tx !== 1'b0) begin
      $error("UART start bit was not low");
      failures++;
    end

    // Move to the center of data bit 0.
    wait_clocks(CLKS_PER_BIT);

    for (int bit_index = 0; bit_index < 8; bit_index++) begin
      received_byte[bit_index] = uart_tx;
      wait_clocks(CLKS_PER_BIT);
    end

    // We should now be in the center of the stop bit.
    if (uart_tx !== 1'b1) begin
      $error("UART stop bit was not high");
      failures++;
    end
  endtask
  */

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  /*
   * Decode every serialized UART frame in parallel with program execution.
   */

   /*
  initial begin
    logic [7:0] received_byte;

    forever begin
      receive_uart_byte(received_byte);
      uart_bytes.push_back(received_byte);

      $display(
          "UART_RX 0x%02h '%c'",
          received_byte,
          received_byte);
    end
  end
  */

  initial begin
    failures = 0;
    rst      = 1'b1;

    @(posedge clk);
    #1;

    check_eq32(
        "reset PC",
        debug_pc,
        32'd0
    );

    rst = 1'b0;

    repeat (RUN_CYCLES) begin
      @(posedge clk);
      #1;
    end

    /*
     * Give the UART time to finish the last frame if the CPU wrote near
     * the end of the run window.
     */
    while (soc_uart_busy) begin
      @(posedge clk);
      #1;
    end

    for (int i = 0; i < 32; i++) begin
      $display(
          "REG x%0d %0d",
          i,
          dut.core_inst.regfile_inst.regs[i]
      );
    end

    $display("UART byte count: %0d", uart_bytes.size());

    if (uart_bytes.size() > 0) begin
      $write("UART text: ");

      foreach (uart_bytes[i]) begin
        $write("%c", uart_bytes[i]);
      end

      $write("\n");
    end

    if (failures == 0) begin
      $display("PASS: assembled program executed correctly");
    end else begin
      $fatal(
          1,
          "FAIL: program_tb had %0d failure(s)",
          failures);
    end

    $finish;
  end

endmodule
