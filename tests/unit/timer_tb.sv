module timer_tb;

  logic clk;
  logic rst;

  logic        write_compare_en;
  logic        write_control_en;
  logic [31:0] write_data;

  logic [31:0] counter;
  logic [31:0] compare;
  logic [31:0] control;
  logic        irq;

  int failures;

  timer dut (
      .clk              (clk),
      .rst              (rst),

      .write_compare_en (write_compare_en),
      .write_control_en (write_control_en),
      .write_data       (write_data),

      .counter          (counter),
      .compare          (compare),
      .control          (control),
      .irq              (irq)
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

  task automatic write_compare(
      input logic [31:0] value
  );
    write_data       = value;
    write_compare_en = 1'b1;
    write_control_en = 1'b0;

    @(posedge clk);
    #1;

    write_compare_en = 1'b0;
  endtask

  task automatic write_control(
      input logic [31:0] value
  );
    write_data       = value;
    write_compare_en = 1'b0;
    write_control_en = 1'b1;

    @(posedge clk);
    #1;

    write_control_en = 1'b0;
  endtask

  task automatic wait_clocks(
      input int count
  );
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
    logic [31:0] count_before;

    failures         = 0;
    rst              = 1'b1;
    write_compare_en = 1'b0;
    write_control_en = 1'b0;
    write_data       = 32'b0;

    // ----------------------------------------------------------
    // Reset
    // ----------------------------------------------------------

    @(posedge clk);
    #1;

    check_eq32("counter after reset", counter, 32'd0);
    check_eq32("compare after reset", compare, 32'd0);
    check_eq32("control after reset", control, 32'd0);
    check_eq1 ("irq after reset", irq, 1'b0);

    rst = 1'b0;

    // ----------------------------------------------------------
    // Counter remains stopped while disabled
    // ----------------------------------------------------------

    wait_clocks(5);

    check_eq32(
        "counter remains zero while disabled",
        counter,
        32'd0
    );

    check_eq1(
        "irq remains low while disabled",
        irq,
        1'b0
    );

    // ----------------------------------------------------------
    // Program compare
    // ----------------------------------------------------------

    write_compare(32'd5);

    check_eq32(
        "compare register write",
        compare,
        32'd5
    );

    check_eq32(
        "counter remains stopped after compare write",
        counter,
        32'd0
    );

    // ----------------------------------------------------------
    // Enable timer without interrupt
    // ----------------------------------------------------------

    write_control(32'b01);

    check_eq32(
        "control enable only",
        control,
        32'b01
    );

    count_before = counter;

    wait_clocks(5);

    check_eq32(
        "counter advances five clocks",
        counter,
        count_before + 32'd5
    );

    check_eq1(
        "irq remains low when interrupt disabled",
        irq,
        1'b0
    );

    // ----------------------------------------------------------
    // Enable interrupt after compare has been reached
    // ----------------------------------------------------------

    count_before = counter;

    write_control(32'b11);

    check_eq32(
        "counter advances during irq-enable write",
        counter,
        count_before + 32'd1
    );

    check_eq32(
        "control enable plus irq enable",
        control,
        32'b11
    );

    check_eq1(
        "irq asserts after interrupt enable",
        irq,
        1'b1
    );

    count_before = counter;

    wait_clocks(3);

    check_eq32(
        "counter advances three clocks",
        counter,
        count_before + 32'd3
    );

    check_eq1(
        "irq remains asserted above compare",
        irq,
        1'b1
    );

    // ----------------------------------------------------------
    // Disable interrupt while keeping timer enabled
    // ----------------------------------------------------------

    count_before = counter;

    write_control(32'b01);

    check_eq32(
        "counter advances during irq-disable write",
        counter,
        count_before + 32'd1
    );

    check_eq1(
        "irq clears when interrupt disabled",
        irq,
        1'b0
    );

    count_before = counter;

    wait_clocks(2);

    check_eq32(
        "counter advances with irq disabled",
        counter,
        count_before + 32'd2
    );

    // ----------------------------------------------------------
    // Disable timer
    // ----------------------------------------------------------

    count_before = counter;

    write_control(32'b00);

    check_eq32(
        "counter advances once during disable write",
        counter,
        count_before + 32'd1
    );

    check_eq32(
        "control disabled",
        control,
        32'b00
    );

    check_eq1(
        "irq low when timer disabled",
        irq,
        1'b0
    );

    count_before = counter;

    wait_clocks(4);

    check_eq32(
        "counter stops after disable",
        counter,
        count_before
    );

    // ----------------------------------------------------------
    // Reprogram compare and restart
    // ----------------------------------------------------------

    write_compare(counter + 32'd3);

    check_eq32(
        "new compare programmed",
        compare,
        counter + 32'd3
    );

    write_control(32'b11);

    check_eq1(
        "irq low before new compare",
        irq,
        1'b0
    );

    count_before = counter;

    wait_clocks(2);

    check_eq32(
        "counter advances toward new compare",
        counter,
        count_before + 32'd2
    );

    check_eq1(
        "irq still low before new compare",
        irq,
        1'b0
    );

    wait_clocks(1);

    check_eq32(
        "counter reaches new compare",
        counter,
        compare
    );

    check_eq1(
        "irq asserts at new compare",
        irq,
        1'b1
    );

    // ----------------------------------------------------------
    // Reset after activity
    // ----------------------------------------------------------

    rst = 1'b1;

    @(posedge clk);
    #1;

    check_eq32("counter after second reset", counter, 32'd0);
    check_eq32("compare after second reset", compare, 32'd0);
    check_eq32("control after second reset", control, 32'd0);
    check_eq1 ("irq after second reset", irq, 1'b0);

    if (failures == 0) begin
      $display("PASS: all timer v2 tests passed");
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
