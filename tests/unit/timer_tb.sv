module timer_tb;

  logic clk;
  logic rst;
  logic [31:0] counter;

  int failures;

  timer dut (
      .clk     (clk),
      .rst     (rst),
      .counter (counter)
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

  initial begin
    failures = 0;
    rst      = 1'b1;

    // Apply synchronous reset.
    @(posedge clk);
    #1;

    check_eq32(
        "counter after reset",
        counter,
        32'd0
    );

    // Release reset.
    rst = 1'b0;

    @(posedge clk);
    #1;
    check_eq32(
        "counter after 1 clock",
        counter,
        32'd1
    );

    @(posedge clk);
    #1;
    check_eq32(
        "counter after 2 clocks",
        counter,
        32'd2
    );

    repeat (8) begin
      @(posedge clk);
      #1;
    end

    check_eq32(
        "counter after 10 clocks",
        counter,
        32'd10
    );

    // Verify reset works again after counting.
    rst = 1'b1;

    @(posedge clk);
    #1;

    check_eq32(
        "counter after second reset",
        counter,
        32'd0
    );

    rst = 1'b0;

    @(posedge clk);
    #1;

    check_eq32(
        "counter restarts after reset",
        counter,
        32'd1
    );

    if (failures == 0) begin
      $display("PASS: all timer tests passed");
    end else begin
      $fatal(
          1,
          "FAIL: timer_tb had %0d failure(s)",
          failures
      );
    end

    $finish;
  end

endmodule
