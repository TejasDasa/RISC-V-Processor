
module decoder_tb ();

  import riscv_pkg::*;

  logic [31:0] instr;

  logic [4:0] rd_addr;
  logic [4:0] rs1_addr;
  logic [4:0] rs2_addr;

  riscv_pkg::alu_op_t alu_op;
  riscv_pkg::imm_type_t imm_type;

  logic reg_write_en;
  logic alu_src_imm;
  logic illegal_instr;

  decoder dut (
      .instr(instr),
      .rd_addr(rd_addr),
      .rs1_addr(rs1_addr),
      .rs2_addr(rs2_addr),
      .alu_op(alu_op),
      .imm_type(imm_type),
      .reg_write_en(reg_write_en),
      .alu_src_imm(alu_src_imm),
      .illegal_instr(illegal_instr)
  );

  int failures;

  task automatic check_eq5(input string test_name, input logic [4:0] actual,
                           input logic [4:0] expected);
    if (actual !== expected) begin
      $error("%s failed: expected 0x%0d, got 0x%0d", test_name, expected, actual);
      failures++;
    end
  endtask

  task automatic check_eq1(input string test_name, input logic actual, input logic expected);
    if (actual !== expected) begin
      $error("%s failed: expected 0b%0b, got 0b%0b", test_name, expected, actual);
      failures++;
    end
  endtask

  initial begin

    failures = 0;

    // LUI Test
    instr = 32'd0;
    instr[6:0] = OPCODE_LUI;
    instr[11:7] = 5'd5;
    instr[31:12] = 20'h12345;
    #1;

    check_eq5("LUI rd addr", rd_addr, 5'd5);
    check_eq1("LUI reg write en", reg_write_en, 1'b1);
    check_eq1("LUI alu src imm", alu_src_imm, 1'b1);
    check_eq1("LUI illegal instr", illegal_instr, 1'b0);

    if (imm_type != IMM_U) $error("Imm type incorrect");
    if (alu_op != ALU_ADD) $error("ALU op incorrect");


    // ADDI Test
    instr = 32'd0;
    instr[6:0] = OPCODE_OP_IMM;
    instr[11:7] = 5'd3;
    instr[14:12] = FUNCT3_ADD_SUB;
    instr[19:15] = 5'd1;
    instr[31:20] = 12'd7;
    #1;

    check_eq5("ADDI rd", rd_addr, 5'd3);
    check_eq5("ADDI rs1", rs1_addr, 5'd1);
    check_eq1("ADDI reg write en", reg_write_en, 1'b1);
    check_eq1("ADDI alu src imm", alu_src_imm, 1'b1);
    check_eq1("ADDI illegal instr", illegal_instr, 1'b0);

    if (imm_type != IMM_I) $error("Imm type incorrect");
    if (alu_op != ALU_ADD) $error("ALU op incorrect");


    // ADD Test
    instr = 32'd0;
    instr[6:0] = OPCODE_OP;
    instr[11:7] = 5'd4;
    instr[14:12] = FUNCT3_ADD_SUB;
    instr[19:15] = 5'd1;
    instr[24:20] = 5'd2;
    instr[31:25] = FUNCT7_ADD_SRL;
    #1;

    check_eq5("ADD rd", rd_addr, 5'd4);
    check_eq5("ADD rs1", rs1_addr, 5'd1);
    check_eq5("ADD rs2", rs2_addr, 5'd2);
    check_eq1("ADD reg write en", reg_write_en, 1'b1);
    check_eq1("ADD alu src imm", alu_src_imm, 1'b0);
    check_eq1("ADD illegal instr", illegal_instr, 1'b0);

    if (alu_op != ALU_ADD) $error("ALU op incorrect");


    // SUB Test
    instr = 32'd0;
    instr[6:0] = OPCODE_OP;
    instr[11:7] = 5'd5;
    instr[14:12] = FUNCT3_ADD_SUB;
    instr[19:15] = 5'd3;
    instr[24:20] = 5'd4;
    instr[31:25] = FUNCT7_SUB_SRA;
    #1;

    check_eq5("SUB rd", rd_addr, 5'd5);
    check_eq5("SUB rs1", rs1_addr, 5'd3);
    check_eq5("SUB rs2", rs2_addr, 5'd4);
    check_eq1("SUB reg write en", reg_write_en, 1'b1);
    check_eq1("SUB alu src imm", alu_src_imm, 1'b0);
    check_eq1("SUB illegal instr", illegal_instr, 1'b0);

    if (alu_op != ALU_SUB) $error("ALU op incorrect");

    // AND Test
    instr = 32'd0;
    instr[6:0] = OPCODE_OP;
    instr[11:7] = 5'd2;
    instr[14:12] = FUNCT3_AND;
    instr[19:15] = 5'd3;
    instr[24:20] = 5'd4;
    #1;

    check_eq5("AND rd", rd_addr, 5'd2);
    check_eq5("AND rs1", rs1_addr, 5'd3);
    check_eq5("AND rs2", rs2_addr, 5'd4);
    check_eq1("AND reg write en", reg_write_en, 1'b1);
    check_eq1("AND alu src imm", alu_src_imm, 1'b0);
    check_eq1("AND illegal instr", illegal_instr, 1'b0);


    // OR Test
    instr = 32'd0;
    instr[6:0] = OPCODE_OP;
    instr[11:7] = 5'd2;
    instr[14:12] = FUNCT3_OR;
    instr[19:15] = 5'd3;
    instr[24:20] = 5'd4;
    #1;

    check_eq5("OR rd", rd_addr, 5'd2);
    check_eq5("OR rs1", rs1_addr, 5'd3);
    check_eq5("OR rs2", rs2_addr, 5'd4);
    check_eq1("OR reg write en", reg_write_en, 1'b1);
    check_eq1("OR alu src imm", alu_src_imm, 1'b0);
    check_eq1("OR illegal instr", illegal_instr, 1'b0);


    // XOR Test
    instr = 32'd0;
    instr[6:0] = OPCODE_OP;
    instr[11:7] = 5'd2;
    instr[14:12] = FUNCT3_XOR;
    instr[19:15] = 5'd3;
    instr[24:20] = 5'd4;
    #1;

    check_eq5("XOR rd", rd_addr, 5'd2);
    check_eq5("XOR rs1", rs1_addr, 5'd3);
    check_eq5("XOR rs2", rs2_addr, 5'd4);
    check_eq1("XOR reg write en", reg_write_en, 1'b1);
    check_eq1("XOR alu src imm", alu_src_imm, 1'b0);
    check_eq1("XOR illegal instr", illegal_instr, 1'b0);


    // SLL Test
    instr = 32'd0;
    instr[6:0] = OPCODE_OP;
    instr[11:7] = 5'd2;
    instr[14:12] = FUNCT3_SLL;
    instr[19:15] = 5'd3;
    instr[24:20] = 5'd4;
    #1;

    check_eq5("SLL rd", rd_addr, 5'd2);
    check_eq5("SLL rs1", rs1_addr, 5'd3);
    check_eq5("SLL rs2", rs2_addr, 5'd4);
    check_eq1("SLL reg write en", reg_write_en, 1'b1);
    check_eq1("SLL alu src imm", alu_src_imm, 1'b0);
    check_eq1("SLL illegal instr", illegal_instr, 1'b0);


    // SLT Test
    instr = 32'd0;
    instr[6:0] = OPCODE_OP;
    instr[11:7] = 5'd2;
    instr[14:12] = FUNCT3_SLT;
    instr[19:15] = 5'd3;
    instr[24:20] = 5'd4;
    #1;

    check_eq5("SLT rd", rd_addr, 5'd2);
    check_eq5("SLT rs1", rs1_addr, 5'd3);
    check_eq5("SLT rs2", rs2_addr, 5'd4);
    check_eq1("SLT reg write en", reg_write_en, 1'b1);
    check_eq1("SLT alu src imm", alu_src_imm, 1'b0);
    check_eq1("SLT illegal instr", illegal_instr, 1'b0);


    // Illegal Instruction Test
    instr = 32'd0;
    #1 check_eq1("Illegal pass", illegal_instr, 1'b1);
    check_eq1("Illegal register lock", reg_write_en, 1'b0);


    if (failures == 0) begin
      $display("PASS: all decoder tests passed");
    end else begin
      $fatal(1, "FAIL: decoder_tb had %0d failure(s)", failures);
    end

    $finish;
  end

endmodule
