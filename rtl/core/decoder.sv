
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
    assign rd_addr = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1_addr = instr[19:15];
    assign rs2_addr = instr[24:20];
    assign funct7 = instr[31:25];

  end

  always_comb begin

    alu_op = ALU_ADD;
    imm_type = IMM_I;
    reg_write_en = 1'b0;
    alu_src_imm = 1'b0;
    illegal_instr = 1'b0;

    unique case (opcode)

      OPCODE_LUI: begin
        reg_write_en = 1'b1;
        alu_src_imm = 1'b1;
        imm_type = IMM_U;
        alu_op = ALU_ADD;
        illegal_instr = 1'b0;
      end

      OPCODE_OP_IMM: begin
        reg_write_en = 1'b1;
        alu_src_imm  = 1'b1;
        case (funct3)
          FUNCT3_ADD_SUB: begin  // ADDI
            imm_type = IMM_I;
            alu_op = ALU_ADD;
            illegal_instr = 1'b0;
          end

          FUNCT3_AND: begin
            imm_type = IMM_I;
            alu_op = ALU_AND;
            illegal_instr = 1'b0;
          end

          default: illegal_instr = 1'b1;
        endcase
      end

      OPCODE_OP: begin
        reg_write_en = 1'b1;
        alu_src_imm  = 1'b0;
        case (funct3)

          FUNCT3_ADD_SUB: begin
            case (funct7)

              FUNCT7_ADD_SRL: begin  // ADD
                alu_op = ALU_ADD;
                illegal_instr = 1'b0;
              end

              FUNCT7_SUB_SRA: begin  // SUB
                alu_op = ALU_SUB;
                illegal_instr = 1'b0;
              end

              default: illegal_instr = 1'b1;

            endcase
          end

          FUNCT3_AND: begin
            alu_op = ALU_AND;
            illegal_instr = 1'b0;
          end

          FUNCT3_OR: begin
            alu_op = ALU_OR;
            illegal_instr = 1'b0;
          end

          FUNCT3_XOR: begin
            alu_op = ALU_XOR;
            illegal_instr = 1'b0;
          end

          FUNCT3_SLL: begin
            alu_op = ALU_SLL;
            illegal_instr = 1'b0;
          end

          FUNCT3_SLT: begin
            alu_op = ALU_SLT;
            illegal_instr = 1'b0;
          end

          FUNCT3_SLTU: begin
            alu_op = ALU_SLTU;
            illegal_instr = 1'b0;
          end

          FUNCT3_SRL_SRA: begin
            case (funct7)
              FUNCT7_ADD_SRL: begin  // SRL
                alu_op = ALU_SRL;
                illegal_instr = 1'b0;
              end

              FUNCT7_SUB_SRA: begin  // SRA
                alu_op = ALU_SRA;
                illegal_instr = 1'b0;
              end

              default: illegal_instr = 1'b1;
            endcase

          end

          default: illegal_instr = 1'b1;
        endcase
      end

      default: illegal_instr = 1'b1;
    endcase

  end

endmodule
