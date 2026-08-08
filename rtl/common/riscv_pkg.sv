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

  // CSR Operations DEF
  typedef enum logic [3:0] {
    CSR_RW,
    CSR_RS
   } csr_op_t;

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

  // Write Back typedef
  typedef enum logic [1:0] {
    WB_ALU = 2'd0,
    WB_MEM = 2'd1,
    WB_PC4 = 2'd2,
    WB_CSR = 2'd3
  } wb_sel_t;

  // ALU selection
  typedef enum logic [1:0] {
    ALU_A_RS1  = 2'd0,
    ALU_A_PC   = 2'd1,
    ALU_A_ZERO = 2'd2
  } alu_a_sel_t;

  // Load types
  typedef enum logic [2:0] {
    LOAD_B,
    LOAD_BU,
    LOAD_H,
    LOAD_HU,
    LOAD_W
  } load_type_t;

  // Store types
  typedef enum logic [1:0] {
    STORE_B,
    STORE_H,
    STORE_W
  } store_type_t;

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
  localparam logic [6:0] OPCODE_SYS = 7'b1110011;

  // Branch funct3 values
  localparam logic [2:0] FUNCT3_BEQ = 3'b000;
  localparam logic [2:0] FUNCT3_BNE = 3'b001;
  localparam logic [2:0] FUNCT3_BLT = 3'b100;
  localparam logic [2:0] FUNCT3_BGE = 3'b101;
  localparam logic [2:0] FUNCT3_BLTU = 3'b110;
  localparam logic [2:0] FUNCT3_BGEU = 3'b111;

  // ALU related funct3 values
  localparam logic [2:0] FUNCT3_ADD_SUB = 3'b000;
  localparam logic [2:0] FUNCT3_SLL = 3'b001;
  localparam logic [2:0] FUNCT3_SLT = 3'b010;
  localparam logic [2:0] FUNCT3_SLTU = 3'b011;
  localparam logic [2:0] FUNCT3_XOR = 3'b100;
  localparam logic [2:0] FUNCT3_SRL_SRA = 3'b101;
  localparam logic [2:0] FUNCT3_OR = 3'b110;
  localparam logic [2:0] FUNCT3_AND = 3'b111;

  // funct7 values
  localparam logic [6:0] FUNCT7_ADD_SRL = 7'b0000000;
  localparam logic [6:0] FUNCT7_SUB_SRA = 7'b0100000;

  // load funct3 values
  localparam logic [2:0] FUNCT3_LB  = 3'b000;
  localparam logic [2:0] FUNCT3_LH  = 3'b001;
  localparam logic [2:0] FUNCT3_LW  = 3'b010;
  localparam logic [2:0] FUNCT3_LBU = 3'b100;
  localparam logic [2:0] FUNCT3_LHU = 3'b101;

  // store funct3 values
  localparam logic [2:0] FUNCT3_SB = 3'b000;
  localparam logic [2:0] FUNCT3_SH = 3'b001;
  localparam logic [2:0] FUNCT3_SW = 3'b010;

  // machine mode funct3
  localparam logic [2:0] FUNCT3_CSRRW = 3'b001;
  localparam logic [2:0] FUNCT3_CSRRS = 3'b010;
  localparam logic [2:0] FUNCT3_CSRRC = 3'b011;

  localparam logic [2:0] FUNCT3_CSRRWI = 3'b101;
  localparam logic [2:0] FUNCT3_CSRRSI = 3'b110;
  localparam logic [2:0] FUNCT3_CSRRCI = 3'b111;

endpackage
