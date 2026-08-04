module decoder_tb;

  import riscv_pkg::*;

  logic [31:0] instr;

  logic [4:0] rd_addr;
  logic [4:0] rs1_addr;
  logic [4:0] rs2_addr;

  alu_op_t     alu_op;
  imm_type_t   imm_type;
  branch_op_t  branch_op;
  wb_sel_t     wb_sel;
  alu_a_sel_t  alu_a_sel;
  load_type_t  load_type;
  store_type_t store_type;

  logic reg_write_en;
  logic alu_src_imm;
  logic illegal_instr;
  logic mem_read_en;
  logic mem_write_en;
  logic jump_en;
  logic jump_reg_en;

  int failures;

  decoder dut (
      .instr          (instr),
      .rd_addr        (rd_addr),
      .rs1_addr       (rs1_addr),
      .rs2_addr       (rs2_addr),
      .alu_op         (alu_op),
      .imm_type       (imm_type),
      .branch_op      (branch_op),
      .wb_sel         (wb_sel),
      .alu_a_sel      (alu_a_sel),
      .load_type      (load_type),
      .store_type     (store_type),
      .reg_write_en   (reg_write_en),
      .alu_src_imm    (alu_src_imm),
      .illegal_instr  (illegal_instr),
      .mem_read_en    (mem_read_en),
      .mem_write_en   (mem_write_en),
      .jump_en        (jump_en),
      .jump_reg_en    (jump_reg_en)
  );

  task automatic check_eq1(
      input string test_name,
      input logic actual,
      input logic expected
  );
    if (actual !== expected) begin
      $error("%s failed: expected %0b, got %0b",
             test_name, expected, actual);
      failures++;
    end
  endtask

  task automatic check_eq5(
      input string test_name,
      input logic [4:0] actual,
      input logic [4:0] expected
  );
    if (actual !== expected) begin
      $error("%s failed: expected %0d, got %0d",
             test_name, expected, actual);
      failures++;
    end
  endtask

  function automatic logic [31:0] encode_i(
      input logic [11:0] imm,
      input logic [4:0]  rs1,
      input logic [2:0]  funct3,
      input logic [4:0]  rd,
      input logic [6:0]  opcode
  );
    return {imm, rs1, funct3, rd, opcode};
  endfunction

  function automatic logic [31:0] encode_s(
      input logic [11:0] imm,
      input logic [4:0]  rs2,
      input logic [4:0]  rs1,
      input logic [2:0]  funct3,
      input logic [6:0]  opcode
  );
    return {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
  endfunction

  function automatic logic [31:0] encode_r(
      input logic [6:0] funct7,
      input logic [4:0] rs2,
      input logic [4:0] rs1,
      input logic [2:0] funct3,
      input logic [4:0] rd,
      input logic [6:0] opcode
  );
    return {funct7, rs2, rs1, funct3, rd, opcode};
  endfunction

  task automatic check_common_load(
      input string name,
      input load_type_t expected_type
  );
    check_eq5({name, " rd"}, rd_addr, 5'd5);
    check_eq5({name, " rs1"}, rs1_addr, 5'd1);
    check_eq1({name, " reg_write_en"}, reg_write_en, 1'b1);
    check_eq1({name, " alu_src_imm"}, alu_src_imm, 1'b1);
    check_eq1({name, " mem_read_en"}, mem_read_en, 1'b1);
    check_eq1({name, " mem_write_en"}, mem_write_en, 1'b0);
    check_eq1({name, " illegal_instr"}, illegal_instr, 1'b0);

    if (imm_type !== IMM_I) begin
      $error("%s imm_type failed", name);
      failures++;
    end
    if (alu_op !== ALU_ADD) begin
      $error("%s alu_op failed", name);
      failures++;
    end
    if (alu_a_sel !== ALU_A_RS1) begin
      $error("%s alu_a_sel failed", name);
      failures++;
    end
    if (wb_sel !== WB_MEM) begin
      $error("%s wb_sel failed", name);
      failures++;
    end
    if (load_type !== expected_type) begin
      $error("%s load_type failed", name);
      failures++;
    end
  endtask

  task automatic check_common_store(
      input string name,
      input store_type_t expected_type
  );
    check_eq5({name, " rs1"}, rs1_addr, 5'd1);
    check_eq5({name, " rs2"}, rs2_addr, 5'd5);
    check_eq1({name, " reg_write_en"}, reg_write_en, 1'b0);
    check_eq1({name, " alu_src_imm"}, alu_src_imm, 1'b1);
    check_eq1({name, " mem_read_en"}, mem_read_en, 1'b0);
    check_eq1({name, " mem_write_en"}, mem_write_en, 1'b1);
    check_eq1({name, " illegal_instr"}, illegal_instr, 1'b0);

    if (imm_type !== IMM_S) begin
      $error("%s imm_type failed", name);
      failures++;
    end
    if (alu_op !== ALU_ADD) begin
      $error("%s alu_op failed", name);
      failures++;
    end
    if (alu_a_sel !== ALU_A_RS1) begin
      $error("%s alu_a_sel failed", name);
      failures++;
    end
    if (store_type !== expected_type) begin
      $error("%s store_type failed", name);
      failures++;
    end
  endtask

  initial begin
    failures = 0;
    instr = 32'b0;
    #1;

    // LUI x5, 0x12345
    instr = {20'h12345, 5'd5, OPCODE_LUI};
    #1;
    check_eq5("LUI rd", rd_addr, 5'd5);
    check_eq1("LUI reg_write_en", reg_write_en, 1'b1);
    check_eq1("LUI alu_src_imm", alu_src_imm, 1'b1);
    check_eq1("LUI illegal_instr", illegal_instr, 1'b0);
    if (imm_type !== IMM_U || alu_op !== ALU_ADD ||
        alu_a_sel !== ALU_A_ZERO || wb_sel !== WB_ALU) begin
      $error("LUI control outputs failed");
      failures++;
    end

    // AUIPC x6, 0x10
    instr = {20'h00010, 5'd6, OPCODE_AUIPC};
    #1;
    check_eq5("AUIPC rd", rd_addr, 5'd6);
    check_eq1("AUIPC reg_write_en", reg_write_en, 1'b1);
    check_eq1("AUIPC alu_src_imm", alu_src_imm, 1'b1);
    check_eq1("AUIPC illegal_instr", illegal_instr, 1'b0);
    if (imm_type !== IMM_U || alu_op !== ALU_ADD ||
        alu_a_sel !== ALU_A_PC || wb_sel !== WB_ALU) begin
      $error("AUIPC control outputs failed");
      failures++;
    end

    // Complete load suite.
    instr = encode_i(12'd8, 5'd1, FUNCT3_LB, 5'd5, OPCODE_LOAD);
    #1; check_common_load("LB", LOAD_B);

    instr = encode_i(12'd8, 5'd1, FUNCT3_LH, 5'd5, OPCODE_LOAD);
    #1; check_common_load("LH", LOAD_H);

    instr = encode_i(12'd8, 5'd1, FUNCT3_LW, 5'd5, OPCODE_LOAD);
    #1; check_common_load("LW", LOAD_W);

    instr = encode_i(12'd8, 5'd1, FUNCT3_LBU, 5'd5, OPCODE_LOAD);
    #1; check_common_load("LBU", LOAD_BU);

    instr = encode_i(12'd8, 5'd1, FUNCT3_LHU, 5'd5, OPCODE_LOAD);
    #1; check_common_load("LHU", LOAD_HU);

    // Illegal load encoding.
    instr = encode_i(12'd8, 5'd1, 3'b011, 5'd5, OPCODE_LOAD);
    #1;
    check_eq1("illegal load illegal_instr", illegal_instr, 1'b1);
    check_eq1("illegal load mem_read_en", mem_read_en, 1'b0);
    check_eq1("illegal load mem_write_en", mem_write_en, 1'b0);
    check_eq1("illegal load reg_write_en", reg_write_en, 1'b0);

    // Complete store suite.
    instr = encode_s(12'd8, 5'd5, 5'd1, FUNCT3_SB, OPCODE_STORE);
    #1; check_common_store("SB", STORE_B);

    instr = encode_s(12'd8, 5'd5, 5'd1, FUNCT3_SH, OPCODE_STORE);
    #1; check_common_store("SH", STORE_H);

    instr = encode_s(12'd8, 5'd5, 5'd1, FUNCT3_SW, OPCODE_STORE);
    #1; check_common_store("SW", STORE_W);

    // Illegal store encoding.
    instr = encode_s(12'd8, 5'd5, 5'd1, 3'b011, OPCODE_STORE);
    #1;
    check_eq1("illegal store illegal_instr", illegal_instr, 1'b1);
    check_eq1("illegal store mem_read_en", mem_read_en, 1'b0);
    check_eq1("illegal store mem_write_en", mem_write_en, 1'b0);
    check_eq1("illegal store reg_write_en", reg_write_en, 1'b0);

    // ADDI x3, x1, 7
    instr = encode_i(12'd7, 5'd1, FUNCT3_ADD_SUB, 5'd3, OPCODE_OP_IMM);
    #1;
    check_eq5("ADDI rd", rd_addr, 5'd3);
    check_eq5("ADDI rs1", rs1_addr, 5'd1);
    check_eq1("ADDI reg_write_en", reg_write_en, 1'b1);
    check_eq1("ADDI alu_src_imm", alu_src_imm, 1'b1);
    check_eq1("ADDI illegal_instr", illegal_instr, 1'b0);
    if (alu_op !== ALU_ADD || imm_type !== IMM_I ||
        alu_a_sel !== ALU_A_RS1 || wb_sel !== WB_ALU) begin
      $error("ADDI controls failed");
      failures++;
    end

    // ADD x4, x1, x2
    instr = encode_r(FUNCT7_ADD_SRL, 5'd2, 5'd1,
                     FUNCT3_ADD_SUB, 5'd4, OPCODE_OP);
    #1;
    check_eq1("ADD reg_write_en", reg_write_en, 1'b1);
    check_eq1("ADD alu_src_imm", alu_src_imm, 1'b0);
    check_eq1("ADD illegal_instr", illegal_instr, 1'b0);
    if (alu_op !== ALU_ADD) begin
      $error("ADD alu_op failed");
      failures++;
    end

    // SUB x4, x1, x2
    instr = encode_r(FUNCT7_SUB_SRA, 5'd2, 5'd1,
                     FUNCT3_ADD_SUB, 5'd4, OPCODE_OP);
    #1;
    if (alu_op !== ALU_SUB || illegal_instr !== 1'b0) begin
      $error("SUB controls failed");
      failures++;
    end

    // BEQ x1, x2, offset
    instr = 32'b0;
    instr[6:0]   = OPCODE_BRANCH;
    instr[14:12] = FUNCT3_BEQ;
    instr[19:15] = 5'd1;
    instr[24:20] = 5'd2;
    #1;
    check_eq1("BEQ reg_write_en", reg_write_en, 1'b0);
    check_eq1("BEQ mem_read_en", mem_read_en, 1'b0);
    check_eq1("BEQ mem_write_en", mem_write_en, 1'b0);
    check_eq1("BEQ illegal_instr", illegal_instr, 1'b0);
    if (branch_op !== BR_EQ || imm_type !== IMM_B) begin
      $error("BEQ controls failed");
      failures++;
    end

    // JAL x1, offset
    instr = 32'b0;
    instr[6:0]  = OPCODE_JAL;
    instr[11:7] = 5'd1;
    #1;
    check_eq1("JAL reg_write_en", reg_write_en, 1'b1);
    check_eq1("JAL jump_en", jump_en, 1'b1);
    check_eq1("JAL jump_reg_en", jump_reg_en, 1'b0);
    check_eq1("JAL illegal_instr", illegal_instr, 1'b0);
    if (imm_type !== IMM_J || wb_sel !== WB_PC4) begin
      $error("JAL controls failed");
      failures++;
    end

    // JALR x1, 0(x5)
    instr = encode_i(12'd0, 5'd5, 3'b000, 5'd1, OPCODE_JALR);
    #1;
    check_eq1("JALR reg_write_en", reg_write_en, 1'b1);
    check_eq1("JALR alu_src_imm", alu_src_imm, 1'b1);
    check_eq1("JALR jump_en", jump_en, 1'b1);
    check_eq1("JALR jump_reg_en", jump_reg_en, 1'b1);
    check_eq1("JALR illegal_instr", illegal_instr, 1'b0);
    if (imm_type !== IMM_I || alu_op !== ALU_ADD ||
        wb_sel !== WB_PC4) begin
      $error("JALR controls failed");
      failures++;
    end

    // Completely unknown opcode must have no side effects.
    instr = 32'h0000_0000;
    #1;
    check_eq1("unknown illegal_instr", illegal_instr, 1'b1);
    check_eq1("unknown reg_write_en", reg_write_en, 1'b0);
    check_eq1("unknown mem_read_en", mem_read_en, 1'b0);
    check_eq1("unknown mem_write_en", mem_write_en, 1'b0);
    check_eq1("unknown jump_en", jump_en, 1'b0);

    if (failures == 0) begin
      $display("PASS: all decoder tests passed");
    end else begin
      $fatal(1, "FAIL: decoder_tb had %0d failure(s)", failures);
    end

    $finish;
  end

endmodule
