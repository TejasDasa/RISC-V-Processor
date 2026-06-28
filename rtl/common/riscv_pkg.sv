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

endpackage
