module core_tb;

  import riscv_pkg::*;

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

  function automatic logic [31:0] encode_i_type(
      input logic [11:0] imm,
      input logic [4:0]  rs1,
      input logic [2:0]  funct3,
      input logic [4:0]  rd,
      input logic [6:0]  opcode
  );
    encode_i_type = {imm, rs1, funct3, rd, opcode};
  endfunction

  function automatic logic [31:0] encode_r_type(
      input logic [6:0] funct7,
      input logic [4:0] rs2,
      input logic [4:0] rs1,
      input logic [2:0] funct3,
      input logic [4:0] rd,
      input logic [6:0] opcode
  );
    encode_r_type = {funct7, rs2, rs1, funct3, rd, opcode};
  endfunction

  function automatic logic [31:0] encode_u_type(
      input logic [19:0] imm20,
      input logic [4:0]  rd,
      input logic [6:0]  opcode
  );
    encode_u_type = {imm20, rd, opcode};
  endfunction

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    failures = 0;

    rst = 1'b1;

    // Program:
    //
    // 0x00: addi x1, x0, 5
    // 0x04: addi x2, x0, 7
    // 0x08: add  x3, x1, x2
    // 0x0c: sub  x4, x3, x1
    // 0x10: lui  x5, 0x12345
    // 0x14: addi x6, x5, -1
    // 0x18: nop
    // 0x1c: nop

    dut.imem_inst.mem[0] = encode_i_type(12'd5, 5'd0, FUNCT3_ADD_SUB, 5'd1, OPCODE_OP_IMM);
    dut.imem_inst.mem[1] = encode_i_type(12'd7, 5'd0, FUNCT3_ADD_SUB, 5'd2, OPCODE_OP_IMM);

    dut.imem_inst.mem[2] = encode_r_type(
        FUNCT7_ADD_SRL, 5'd2, 5'd1, FUNCT3_ADD_SUB, 5'd3, OPCODE_OP
    );

    dut.imem_inst.mem[3] = encode_r_type(
        FUNCT7_SUB_SRA, 5'd1, 5'd3, FUNCT3_ADD_SUB, 5'd4, OPCODE_OP
    );

    dut.imem_inst.mem[4] = encode_u_type(20'h12345, 5'd5, OPCODE_LUI);

    dut.imem_inst.mem[5] = encode_i_type(12'hFFF, 5'd5, FUNCT3_ADD_SUB, 5'd6, OPCODE_OP_IMM);

    // NOP = addi x0, x0, 0
    dut.imem_inst.mem[6] = encode_i_type(12'd0, 5'd0, FUNCT3_ADD_SUB, 5'd0, OPCODE_OP_IMM);
    dut.imem_inst.mem[7] = encode_i_type(12'd0, 5'd0, FUNCT3_ADD_SUB, 5'd0, OPCODE_OP_IMM);

    // Apply synchronous reset.
    @(posedge clk);
    #1;

    check_eq32("core reset pc", debug_pc, 32'd0);

    // Release reset and let the program run.
    rst = 1'b0;

    repeat (8) begin
      @(posedge clk);
      #1;
    end

    check_eq32("x1 after addi", dut.regfile_inst.regs[1], 32'd5);
    check_eq32("x2 after addi", dut.regfile_inst.regs[2], 32'd7);
    check_eq32("x3 after add",  dut.regfile_inst.regs[3], 32'd12);
    check_eq32("x4 after sub",  dut.regfile_inst.regs[4], 32'd7);
    check_eq32("x5 after lui",  dut.regfile_inst.regs[5], 32'h1234_5000);
    check_eq32("x6 after addi -1", dut.regfile_inst.regs[6], 32'h1234_4FFF);

    // x0 should still be hardwired to zero.
    check_eq32("x0 remains zero", dut.regfile_inst.regs[0], 32'd0);

    if (failures == 0) begin
      $display("PASS: core executed basic ALU program");
    end else begin
      $fatal(1, "FAIL: core_tb had %0d failure(s)", failures);
    end

    $finish;
  end

endmodule