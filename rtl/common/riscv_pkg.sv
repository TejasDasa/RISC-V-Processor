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


endpackage
