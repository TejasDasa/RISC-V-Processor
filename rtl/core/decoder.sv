
module decoder (
    input logic [31:0] instr,

    output logic [4:0] rd_addr,
    output logic [4:0] rs1_addr,
    output logic [4:0] rs2_addr,

    output riscv_pkg::alu_op_t   alu_op,
    output riscv_pkg::imm_type_t imm_type,

    output logic reg_write_en,
    output logic alu_src_imm,
    output logic illegal_instr
);

  import riscv_pkg::*;

  logic [6:0] opcode;
  logic [2:0] funct3;
  logic [6:0] funct7;

  always_comb begin

    assign opcode = instr[6:0];
    assign rd = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign funct7 = instr[31:25];
    
  end

  always_comb begin

    alu_op = ALU_ADD;
    imm_type = IMM_I;
    reg_write_en = 0;
    alu_src_imm = 0;
    illegal_instr = 0;

    unique case (opcode)


    endcase


  end



endmodule
