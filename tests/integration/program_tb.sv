module program_tb #(
    parameter string PROGRAM_HEX = "software/build/add.hex",
    parameter string PROGRAM_DMEM_HEX = "software/build/add_dmem.hex"
);

  logic clk;
  logic rst;

  logic [31:0] debug_pc;
  logic [31:0] debug_instr;

  core #(
      .IMEM_INIT_FILE(PROGRAM_HEX),
      .DMEM_INIT_FILE(PROGRAM_DMEM_HEX)
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

  //temporary trace
  /*
  always_ff @(posedge clk) begin
    if (!rst) begin
      $display(
          "PC=%08h INSTR=%08h alu_a_sel=%0d imm=%08h alu_a=%08h alu_b=%08h alu_result=%08h rd=%0d reg_we=%0b wb=%08h",
          dut.pc_current,
          dut.instr,
          dut.alu_a_sel,
          dut.imm,
          dut.alu_a,
          dut.alu_b,
          dut.alu_result,
          dut.rd_addr,
          dut.reg_write_en,
          dut.rd_data
      );
    end
  end
  */

  initial begin
    failures = 0;
    rst = 1'b1;

    @(posedge clk);
    #1;

    check_eq32("reset PC", debug_pc, 32'd0);

    rst = 1'b0;

    // choose clock cycles
    repeat (200) begin
      @(posedge clk);
      #1;
    end

    $display("REG x1 %0d", dut.regfile_inst.regs[1]);
    $display("REG x2 %0d", dut.regfile_inst.regs[2]);
    $display("REG x3 %0d", dut.regfile_inst.regs[3]);
    $display("REG x4 %0d", dut.regfile_inst.regs[4]);
    $display("REG x5 %0d", dut.regfile_inst.regs[5]);
    $display("REG x6 %0d", dut.regfile_inst.regs[6]);
    $display("REG x7 %0d", dut.regfile_inst.regs[7]);
    $display("REG x8 %0d", dut.regfile_inst.regs[8]);
    $display("REG x9 %0d", dut.regfile_inst.regs[9]);
    $display("REG x10 %0d", dut.regfile_inst.regs[10]);


    if (failures == 0) begin
      $display("PASS: assembled program executed correctly");
    end else begin
      $fatal(1, "FAIL: program_tb had %0d failure(s)", failures);
    end

    $finish;
  end

endmodule
