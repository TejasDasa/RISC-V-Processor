module imem_tb;

  logic [31:0] addr;
  logic [31:0] instr;

  imem dut (
      .addr(addr),
      .instr(instr)
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
    failures = 0;

    // Initialize instruction memory
    dut.mem[0] = 32'h1111_1111;
    dut.mem[1] = 32'h2222_2222;
    dut.mem[2] = 32'h3333_3333;
    dut.mem[3] = 32'h4444_4444;

    // addr 0 -> mem[0]
    addr = 32'd0;
    #1;
    check_eq32("imem addr 0", instr, 32'h1111_1111);

    // addr 4 -> mem[1]
    addr = 32'd4;
    #1;
    check_eq32("imem addr 4", instr, 32'h2222_2222);

    // addr 8 -> mem[2]
    addr = 32'd8;
    #1;
    check_eq32("imem addr 8", instr, 32'h3333_3333);

    // addr 12 -> mem[3]
    addr = 32'd12;
    #1;
    check_eq32("imem addr 12", instr, 32'h4444_4444);

    // Unaligned address 5 still maps to addr[9:2] = 1
    addr = 32'd5;
    #1;
    check_eq32("imem unaligned addr 5", instr, 32'h2222_2222);

    if (failures == 0) begin
      $display("PASS: all imem tests passed");
    end else begin
      $fatal(1, "FAIL: imem_tb had %0d failure(s)", failures);
    end

    $finish;
  end

endmodule
