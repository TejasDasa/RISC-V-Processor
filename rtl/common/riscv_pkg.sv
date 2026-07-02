package riscv_pkg;

  // ALU Operations DEF
  typedef enum logic [3:0] {
    ALU_ADD,
    ALU_SUB,
    ALU_AND,
    ALU_OR,
    ALU_XOR,
    ALU_SLL,
    ALU_SRL,
    ALU_SRA,
    ALU_SLT,
    ALU_SLTU
  } alu_op_t;

  // Imm Type DEF
  typedef enum logic [2:0] {
    IMM_I,
    IMM_S,
    IMM_B,
    IMM_U,
    IMM_J
  } imm_type_t;

  // Branch Type DEF
  typedef enum logic [2:0] {
    BR_NONE,
    BR_EQ,
    BR_NE,
    BR_LT,
    BR_GE,
    BR_LTU,
    BR_GEU
  } branch_op_t;

  // OPCODE Constants
  localparam logic [6:0] OPCODE_LUI = 7'b0110111;
  localparam logic [6:0] OPCODE_AUIPC = 7'b0010111;
  localparam logic [6:0] OPCODE_JAL = 7'b1101111;
  localparam logic [6:0] OPCODE_JALR = 7'b1100111;
  localparam logic [6:0] OPCODE_BRANCH = 7'b1100011;
  localparam logic [6:0] OPCODE_LOAD = 7'b0000011;
  localparam logic [6:0] OPCODE_STORE = 7'b0100011;
  localparam logic [6:0] OPCODE_OP_IMM = 7'b0010011;
  localparam logic [6:0] OPCODE_OP = 7'b0110011;

  // Branch func3 values
  localparam logic [2:0] FUNCT3_BEQ = 3'b000;
  localparam logic [2:0] FUNCT3_BNE = 3'b001;
  localparam logic [2:0] FUNCT3_BLT = 3'b100;
  localparam logic [2:0] FUNCT3_BGE = 3'b101;
  localparam logic [2:0] FUNCT3_BLTU = 3'b110;
  localparam logic [2:0] FUNCT3_BGEU = 3'b111;

  // ALU related func3 values
  localparam logic [2:0] FUNCT3_ADD_SUB = 3'b000;
  localparam logic [2:0] FUNCT3_SLL = 3'b001;
  localparam logic [2:0] FUNCT3_SLT = 3'b010;
  localparam logic [2:0] FUNCT3_SLTU = 3'b011;
  localparam logic [2:0] FUNCT3_XOR = 3'b100;
  localparam logic [2:0] FUNCT3_SRL_SRA = 3'b101;
  localparam logic [2:0] FUNCT3_OR = 3'b110;
  localparam logic [2:0] FUNCT3_AND = 3'b111;

  // func7 values
  localparam logic [6:0] FUNCT7_ADD_SRL = 7'b0000000;
  localparam logic [6:0] FUNCT7_SUB_SRA = 7'b0100000;

  // word access func3 values
  localparam logic [2:0] FUNCT3_LW = 3'b010;
  localparam logic [2:0] FUNCT3_SW = 3'b010;

endpackage
