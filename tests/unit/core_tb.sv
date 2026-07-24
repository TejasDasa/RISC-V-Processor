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

  function automatic logic [31:0] encode_s_type(
      input logic [11:0] imm,
      input logic [4:0]  rs2,
      input logic [4:0]  rs1,
      input logic [2:0]  funct3,
      input logic [6:0]  opcode
  );
    encode_s_type = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
  endfunction

  function automatic logic [31:0] encode_b_type(
      input logic [12:0] imm,
      input logic [4:0]  rs2,
      input logic [4:0]  rs1,
      input logic [2:0]  funct3,
      input logic [6:0]  opcode
  );
    encode_b_type = {
        imm[12],
        imm[10:5],
        rs2,
        rs1,
        funct3,
        imm[4:1],
        imm[11],
        opcode};
  endfunction

  function automatic logic [31:0] encode_j_type(
    input logic [20:0] imm,
    input logic [4:0]  rd,
    input logic [6:0]  opcode
);
  encode_j_type = {
      imm[20],
      imm[10:1],
      imm[11],
      imm[19:12],
      rd,
      opcode};
endfunction

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    failures = 0;

    rst = 1'b1;

    // 0x00: addi x10, x0, 5
dut.imem_inst.mem[0] =
    encode_i_type(
        12'd5,
        5'd0,
        FUNCT3_ADD_SUB,
        5'd10,
        OPCODE_OP_IMM
    );

// 0x04: jal x1, function
//
// Current PC = 0x04
// Function PC = 0x10
// Offset = 0x10 - 0x04 = 12 bytes
dut.imem_inst.mem[1] =
    encode_j_type(
        21'd12,
        5'd1,
        OPCODE_JAL
    );

// 0x08: addi x3, x0, 42
// This executes after returning from the function.
dut.imem_inst.mem[2] =
    encode_i_type(
        12'd42,
        5'd0,
        FUNCT3_ADD_SUB,
        5'd3,
        OPCODE_OP_IMM
    );

// 0x0c: jal x0, done
//
// Current PC = 0x0c
// Done PC = 0x18
// Offset = 0x18 - 0x0c = 12 bytes
dut.imem_inst.mem[3] =
    encode_j_type(
        21'd12,
        5'd0,
        OPCODE_JAL
    );

// 0x10: function: addi x10, x10, 7
dut.imem_inst.mem[4] =
    encode_i_type(
        12'd7,
        5'd10,
        FUNCT3_ADD_SUB,
        5'd10,
        OPCODE_OP_IMM
    );

// 0x14: jalr x0, 0(x1)
//
// x1 contains the return address, 0x08.
// rd = x0 because returns do not save another return address.
dut.imem_inst.mem[5] =
    encode_i_type(
        12'd0,
        5'd1,
        3'b000,
        5'd0,
        OPCODE_JALR
    );

// 0x18: done: addi x4, x0, 99
dut.imem_inst.mem[6] =
    encode_i_type(
        12'd99,
        5'd0,
        FUNCT3_ADD_SUB,
        5'd4,
        OPCODE_OP_IMM
    );

// NOPs
dut.imem_inst.mem[7] =
    encode_i_type(
        12'd0,
        5'd0,
        FUNCT3_ADD_SUB,
        5'd0,
        OPCODE_OP_IMM
    );

dut.imem_inst.mem[8] =
    encode_i_type(
        12'd0,
        5'd0,
        FUNCT3_ADD_SUB,
        5'd0,
        OPCODE_OP_IMM
    );

    // Apply synchronous reset.
    @(posedge clk);
    #1;

    check_eq32("taken test reset pc", debug_pc, 32'd0);

    // Release reset and let the program run.
    rst = 1'b0;

    repeat (8) begin
      @(posedge clk);
      #1;
    end

    check_eq32(
        "JAL saved return address in x1",
        dut.regfile_inst.regs[1],
        32'h0000_0008
    );

    check_eq32(
        "function updated x10",
        dut.regfile_inst.regs[10],
        32'd12
    );

    check_eq32(
        "JALR returned to caller",
        dut.regfile_inst.regs[3],
        32'd42
    );

    check_eq32(
        "JAL x0 reached done",
        dut.regfile_inst.regs[4],
        32'd99
    );

    // x0 should still be hardwired to zero.
    check_eq32("x0 remains zero", dut.regfile_inst.regs[0], 32'd0);

    if (failures == 0) begin
      $display("PASS: core executed jump program");
    end else begin
      $fatal(1, "FAIL: core_tb had %0d failure(s)", failures);
    end

    $finish;
  end

endmodule