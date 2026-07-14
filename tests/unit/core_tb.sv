module core_tb;

  logic clk;
  logic rst;

  logic [31:0] debug_pc;
  logic [31:0] debug_instr;

  core dut (
      .clk(clk),
      .rst(rst),
      .debug_pc(debug_pc),
      .debug_instr(debug_instr)
  );

  int failures;

  task automatic check_eq32(
      input string test_name,
      input logic [31:0] actual,
      input logic [31:0] expected
  );
    if (actual !== expected) begin
      $error("%s failed: expected 0x%08h, got 0x%08h",
             test_name, expected, actual);
      failures++;
    end
  endtask

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    failures = 0;

    rst = 1'b1;

    // Initialize instruction memory through hierarchical access
    dut.imem_inst.mem[0] = 32'h1111_1111;
    dut.imem_inst.mem[1] = 32'h2222_2222;
    dut.imem_inst.mem[2] = 32'h3333_3333;
    dut.imem_inst.mem[3] = 32'h4444_4444;

    // Apply synchronous reset
    @(posedge clk);
    #1;

    check_eq32("core reset pc", debug_pc, 32'd0);
    check_eq32("core instr at pc 0", debug_instr, 32'h1111_1111);

    // Release reset. Next clock should advance PC to 4.
    rst = 1'b0;

    @(posedge clk);
    #1;
    check_eq32("core pc 4", debug_pc, 32'd4);
    check_eq32("core instr at pc 4", debug_instr, 32'h2222_2222);

    @(posedge clk);
    #1;
    check_eq32("core pc 8", debug_pc, 32'd8);
    check_eq32("core instr at pc 8", debug_instr, 32'h3333_3333);

    @(posedge clk);
    #1;
    check_eq32("core pc 12", debug_pc, 32'd12);
    check_eq32("core instr at pc 12", debug_instr, 32'h4444_4444);

    if (failures == 0) begin
      $display("PASS: all core skeleton tests passed");
    end else begin
      $fatal(1, "FAIL: core_tb had %0d failure(s)", failures);
    end

    $finish;
  end

endmodule
