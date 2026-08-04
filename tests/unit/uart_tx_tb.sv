module uart_tx_tb;

  localparam int CLOCK_HZ     = 10;
  localparam int BAUD_RATE    = 2;
  localparam int CLKS_PER_BIT = CLOCK_HZ / BAUD_RATE;

  logic clk;
  logic rst;

  logic       valid;
  logic [7:0] data;

  logic tx;
  logic busy;

  uart_tx #(
      .CLOCK_HZ(CLOCK_HZ),
      .BAUD_RATE(BAUD_RATE)
  ) dut (
      .clk  (clk),
      .rst  (rst),
      .valid(valid),
      .data (data),
      .tx   (tx),
      .busy (busy)
  );

  int failures;

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

  task automatic wait_bit_period;
    repeat (CLKS_PER_BIT) begin
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
    valid    = 1'b0;
    data     = 8'h00;

    // Apply synchronous reset.
    @(posedge clk);
    #1;

    check_eq1("reset tx idle high", tx, 1'b1);
    check_eq1("reset busy low", busy, 1'b0);

    rst = 1'b0;

    // Send ASCII 'H' = 0x48 = 8'b0100_1000.
    data  = 8'h48;
    valid = 1'b1;

    @(posedge clk);
    #1;

    valid = 1'b0;

    // UART should now be in the START state.
    check_eq1("busy after valid", busy, 1'b1);
    check_eq1("start bit", tx, 1'b0);

    // Finish the start-bit period.
    wait_bit_period();

    // Data bits are sent LSB-first.
    check_eq1("data bit 0", tx, 1'b0);
    wait_bit_period();

    check_eq1("data bit 1", tx, 1'b0);
    wait_bit_period();

    check_eq1("data bit 2", tx, 1'b0);
    wait_bit_period();

    check_eq1("data bit 3", tx, 1'b1);
    wait_bit_period();

    check_eq1("data bit 4", tx, 1'b0);
    wait_bit_period();

    check_eq1("data bit 5", tx, 1'b0);
    wait_bit_period();

    check_eq1("data bit 6", tx, 1'b1);
    wait_bit_period();

    check_eq1("data bit 7", tx, 1'b0);
    wait_bit_period();

    // Stop bit.
    check_eq1("stop bit", tx, 1'b1);
    check_eq1("busy during stop", busy, 1'b1);

    wait_bit_period();

    // Return to idle.
    check_eq1("tx idle after frame", tx, 1'b1);
    check_eq1("busy low after frame", busy, 1'b0);

    if (failures == 0) begin
      $display("PASS: UART transmitted 0x48 correctly");
    end else begin
      $fatal(1, "FAIL: uart_tx_tb had %0d failure(s)", failures);
    end

    $finish;
  end

endmodule