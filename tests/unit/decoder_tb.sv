
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
  logic mem_read_en;
  logic mem_write_en;
  logic mem_to_reg;

  decoder dut (
      .instr(instr),
      .rd_addr(rd_addr),
      .rs1_addr(rs1_addr),
      .rs2_addr(rs2_addr),
      .alu_op(alu_op),
      .imm_type(imm_type),
      .reg_write_en(reg_write_en),
      .alu_src_imm(alu_src_imm),
      .mem_read_en(mem_read_en),
      .mem_write_en(mem_write_en),
      .mem_to_reg(mem_to_reg),
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

    // LW x5, 8(x1)
    instr = 32'b0;
    instr[6:0]   = OPCODE_LOAD;
    instr[11:7]  = 5'd5;       // rd = x5
    instr[14:12] = FUNCT3_LW;
    instr[19:15] = 5'd1;       // rs1 = x1 base address
    instr[31:20] = 12'd8;      // offset = 8
    #1;

    check_eq5("LW rd addr", rd_addr, 5'd5);
    check_eq5("LW rs1 addr", rs1_addr, 5'd1);

    check_eq1("LW reg write en", reg_write_en, 1'b1);
    check_eq1("LW alu src imm", alu_src_imm, 1'b1);
    check_eq1("LW mem read en", mem_read_en, 1'b1);
    check_eq1("LW mem write en", mem_write_en, 1'b0);
    check_eq1("LW mem to reg", mem_to_reg, 1'b1);
    check_eq1("LW illegal instr", illegal_instr, 1'b0);

    if (imm_type !== IMM_I) begin
      $error("LW imm_type failed: expected IMM_I");
      failures++;
    end

    if (alu_op !== ALU_ADD) begin
      $error("LW alu_op failed: expected ALU_ADD");
      failures++;
    end


    // SW x5, 8(x1)
    // rs1 = x1 base address
    // rs2 = x5 data to store
    instr = 32'b0;
    instr[6:0]    = OPCODE_STORE;
    instr[14:12]  = FUNCT3_SW;
    instr[19:15]  = 5'd1;       // rs1 = x1
    instr[24:20]  = 5'd5;       // rs2 = x5
    instr[31:25]  = 7'b0000000; // imm[11:5]
    instr[11:7]   = 5'b01000;   // imm[4:0] = 8
    #1;

    check_eq5("SW rs1 addr", rs1_addr, 5'd1);
    check_eq5("SW rs2 addr", rs2_addr, 5'd5);

    check_eq1("SW reg write en", reg_write_en, 1'b0);
    check_eq1("SW alu src imm", alu_src_imm, 1'b1);
    check_eq1("SW mem read en", mem_read_en, 1'b0);
    check_eq1("SW mem write en", mem_write_en, 1'b1);
    check_eq1("SW mem to reg", mem_to_reg, 1'b0);
    check_eq1("SW illegal instr", illegal_instr, 1'b0);

    if (imm_type !== IMM_S) begin
      $error("SW imm_type failed: expected IMM_S");
      failures++;
    end

    if (alu_op !== ALU_ADD) begin
      $error("SW alu_op failed: expected ALU_ADD");
      failures++;
    end


    // Illegal LOAD funct3
    instr = 32'b0;
    instr[6:0]   = OPCODE_LOAD;
    instr[11:7]  = 5'd5;
    instr[14:12] = 3'b000;      // unsupported load type for now
    instr[19:15] = 5'd1;
    instr[31:20] = 12'd8;
    #1;

    check_eq1("illegal LOAD illegal instr", illegal_instr, 1'b1);
    check_eq1("illegal LOAD reg write en", reg_write_en, 1'b0);
    check_eq1("illegal LOAD mem read en", mem_read_en, 1'b0);
    check_eq1("illegal LOAD mem write en", mem_write_en, 1'b0);


    // Illegal STORE funct3
    instr = 32'b0;
    instr[6:0]    = OPCODE_STORE;
    instr[14:12]  = 3'b000;      // unsupported store type for now
    instr[19:15]  = 5'd1;
    instr[24:20]  = 5'd5;
    instr[31:25]  = 7'b0000000;
    instr[11:7]   = 5'b01000;
    #1;

    check_eq1("illegal STORE illegal instr", illegal_instr, 1'b1);
    check_eq1("illegal STORE reg write en", reg_write_en, 1'b0);
    check_eq1("illegal STORE mem read en", mem_read_en, 1'b0);
    check_eq1("illegal STORE mem write en", mem_write_en, 1'b0);


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

    
    // ANDI Test
    instr = 32'd0;
    instr[6:0] = OPCODE_OP_IMM;
    instr[11:7] = 5'd9;
    instr[14:12] = FUNCT3_AND;
    instr[19:15] = 5'd1;
    instr[31:20] = 12'd0;
    #1;

    check_eq5("ANDI rd", rd_addr, 5'd9);
    check_eq5("ANDI rs1", rs1_addr, 5'd1);
    check_eq1("ANDI reg write en", reg_write_en, 1'b1);
    check_eq1("ANDI alu src imm", alu_src_imm, 1'b1);
    check_eq1("ANDI illegal instr", illegal_instr, 1'b0);

    if (imm_type != IMM_I) $error("Imm type incorrect");
    if (alu_op != ALU_AND) $error("ALU op incorrect");


    // ORI Test
    instr = 32'd0;
    instr[6:0] = OPCODE_OP_IMM;
    instr[11:7] = 5'd9;
    instr[14:12] = FUNCT3_OR;
    instr[19:15] = 5'd1;
    instr[31:20] = 12'd0;
    #1;

    check_eq5("ORI rd", rd_addr, 5'd9);
    check_eq5("ORI rs1", rs1_addr, 5'd1);
    check_eq1("ORI reg write en", reg_write_en, 1'b1);
    check_eq1("ORI alu src imm", alu_src_imm, 1'b1);
    check_eq1("ORI illegal instr", illegal_instr, 1'b0);

    if (imm_type != IMM_I) $error("Imm type incorrect");
    if (alu_op != ALU_OR) $error("ALU op incorrect");


    // XORI x11, x1, imm
    instr = 32'b0;
    instr[6:0]   = OPCODE_OP_IMM;
    instr[11:7]  = 5'd11;
    instr[14:12] = FUNCT3_XOR;
    instr[19:15] = 5'd1;
    instr[31:20] = 12'h0FF;
    #1;

    check_eq5("XORI rd addr", rd_addr, 5'd11);
    check_eq5("XORI rs1 addr", rs1_addr, 5'd1);
    check_eq1("XORI reg write en", reg_write_en, 1'b1);
    check_eq1("XORI alu src imm", alu_src_imm, 1'b1);
    check_eq1("XORI illegal instr", illegal_instr, 1'b0);

    if (imm_type !== IMM_I) begin
      $error("XORI imm_type failed: expected IMM_I");
      failures++;
    end

    if (alu_op !== ALU_XOR) begin
      $error("XORI alu_op failed: expected ALU_XOR");
      failures++;
    end

    // SLTI x12, x1, imm
    instr = 32'b0;
    instr[6:0]   = OPCODE_OP_IMM;
    instr[11:7]  = 5'd12;          // rd = x12
    instr[14:12] = FUNCT3_SLT;     // SLTI
    instr[19:15] = 5'd1;           // rs1 = x1
    instr[31:20] = 12'd5;          // immediate
    #1;

    check_eq5("SLTI rd addr", rd_addr, 5'd12);
    check_eq5("SLTI rs1 addr", rs1_addr, 5'd1);
    check_eq1("SLTI reg write en", reg_write_en, 1'b1);
    check_eq1("SLTI alu src imm", alu_src_imm, 1'b1);
    check_eq1("SLTI illegal instr", illegal_instr, 1'b0);

    if (imm_type !== IMM_I) begin
      $error("SLTI imm_type failed: expected IMM_I");
      failures++;
    end

    if (alu_op !== ALU_SLT) begin
      $error("SLTI alu_op failed: expected ALU_SLT");
      failures++;
    end


    // SLTIU x13, x1, imm
    instr = 32'b0;
    instr[6:0]   = OPCODE_OP_IMM;
    instr[11:7]  = 5'd13;          // rd = x13
    instr[14:12] = FUNCT3_SLTU;    // SLTIU
    instr[19:15] = 5'd1;           // rs1 = x1
    instr[31:20] = 12'd5;          // immediate
    #1;

    check_eq5("SLTIU rd addr", rd_addr, 5'd13);
    check_eq5("SLTIU rs1 addr", rs1_addr, 5'd1);
    check_eq1("SLTIU reg write en", reg_write_en, 1'b1);
    check_eq1("SLTIU alu src imm", alu_src_imm, 1'b1);
    check_eq1("SLTIU illegal instr", illegal_instr, 1'b0);

    if (imm_type !== IMM_I) begin
      $error("SLTIU imm_type failed: expected IMM_I");
      failures++;
    end

    if (alu_op !== ALU_SLTU) begin
      $error("SLTIU alu_op failed: expected ALU_SLTU");
      failures++;
    end


    // SLLI x14, x1, 3
    instr = 32'b0;
    instr[6:0]   = OPCODE_OP_IMM;
    instr[11:7]  = 5'd14;            // rd = x14
    instr[14:12] = FUNCT3_SLL;       // SLLI
    instr[19:15] = 5'd1;             // rs1 = x1
    instr[24:20] = 5'd3;             // shamt = 3
    instr[31:25] = FUNCT7_ADD_SRL;   // required for SLLI
    #1;

    check_eq5("SLLI rd addr", rd_addr, 5'd14);
    check_eq5("SLLI rs1 addr", rs1_addr, 5'd1);
    check_eq1("SLLI reg write en", reg_write_en, 1'b1);
    check_eq1("SLLI alu src imm", alu_src_imm, 1'b1);
    check_eq1("SLLI illegal instr", illegal_instr, 1'b0);

    if (imm_type !== IMM_I) begin
      $error("SLLI imm_type failed: expected IMM_I");
      failures++;
    end

    if (alu_op !== ALU_SLL) begin
      $error("SLLI alu_op failed: expected ALU_SLL");
      failures++;
    end


    // SRLI x15, x1, 3
    instr = 32'b0;
    instr[6:0]   = OPCODE_OP_IMM;
    instr[11:7]  = 5'd15;            // rd = x15
    instr[14:12] = FUNCT3_SRL_SRA;   // SRLI/SRAI group
    instr[19:15] = 5'd1;             // rs1 = x1
    instr[24:20] = 5'd3;             // shamt = 3
    instr[31:25] = FUNCT7_ADD_SRL;   // SRLI
    #1;

    check_eq5("SRLI rd addr", rd_addr, 5'd15);
    check_eq5("SRLI rs1 addr", rs1_addr, 5'd1);
    check_eq1("SRLI reg write en", reg_write_en, 1'b1);
    check_eq1("SRLI alu src imm", alu_src_imm, 1'b1);
    check_eq1("SRLI illegal instr", illegal_instr, 1'b0);

    if (imm_type !== IMM_I) begin
      $error("SRLI imm_type failed: expected IMM_I");
      failures++;
    end

    if (alu_op !== ALU_SRL) begin
      $error("SRLI alu_op failed: expected ALU_SRL");
      failures++;
    end


    // SRAI x16, x1, 3
    instr = 32'b0;
    instr[6:0]   = OPCODE_OP_IMM;
    instr[11:7]  = 5'd16;            // rd = x16
    instr[14:12] = FUNCT3_SRL_SRA;   // SRLI/SRAI group
    instr[19:15] = 5'd1;             // rs1 = x1
    instr[24:20] = 5'd3;             // shamt = 3
    instr[31:25] = FUNCT7_SUB_SRA;   // SRAI
    #1;

    check_eq5("SRAI rd addr", rd_addr, 5'd16);
    check_eq5("SRAI rs1 addr", rs1_addr, 5'd1);
    check_eq1("SRAI reg write en", reg_write_en, 1'b1);
    check_eq1("SRAI alu src imm", alu_src_imm, 1'b1);
    check_eq1("SRAI illegal instr", illegal_instr, 1'b0);

    if (imm_type !== IMM_I) begin
      $error("SRAI imm_type failed: expected IMM_I");
      failures++;
    end

    if (alu_op !== ALU_SRA) begin
      $error("SRAI alu_op failed: expected ALU_SRA");
      failures++;
    end


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
