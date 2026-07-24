module program_tb;

  logic clk;
  logic rst;

  logic [31:0] debug_pc;
  logic [31:0] debug_instr;

  core #(
      .IMEM_INIT_FILE("software/build/add.hex")
  ) dut (
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
    rst = 1'b1;

    @(posedge clk);
    #1;

    check_eq32("reset PC", debug_pc, 32'd0);

    rst = 1'b0;

    // Three useful instructions, followed by an infinite JAL loop.
    repeat (8) begin
      @(posedge clk);
      #1;
    end

    check_eq32(
        "assembled ADDI wrote x1",
        dut.regfile_inst.regs[1],
        32'd5
    );

    check_eq32(
        "assembled ADDI wrote x2",
        dut.regfile_inst.regs[2],
        32'd7
    );

    check_eq32(
        "assembled ADD wrote x3",
        dut.regfile_inst.regs[3],
        32'd12
    );

    if (failures == 0) begin
      $display("PASS: assembled program executed correctly");
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
