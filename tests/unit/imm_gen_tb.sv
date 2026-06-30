
module imm_gen_tb;

  import riscv_pkg::*;

  logic [31:0] instr;
  riscv_pkg::imm_type_t imm_type;

  logic [31:0] imm;

  imm_gen dut (
      .instr(instr),
      .imm_type(imm_type),
      .imm(imm)
  );

  initial begin
    instr = 32'b0;
    instr[31:20] = 12'd5;
    imm_type = IMM_I;
    #1;

    if (imm != 32'd5) $error("IMM_I positive failed: expected 5, got 0x%08h", imm);

    instr = 32'b0;
    instr[31:20] = 12'hFFF;
    imm_type = IMM_I;
    #1;

    if (imm != 32'hFFFFFFFF) $error("IMM_I negative failed: expected 0xFFFFFFFF, got 0x%08h", imm);

    instr = 32'b0;
    instr[31:20] = 12'h800;
    imm_type = IMM_I;
    #1;

    if (imm != 32'hFFFF_F800) $error("IMM_I -2048 failed: expected 0xFFFFF800, got 0x%08h", imm);

    instr = 32'b0;

    instr[31] = 1'b0;
    instr[7] = 1'b0;
    instr[30:25] = 6'b000000;
    instr[11:8] = 4'b0100;
    imm_type = IMM_B;
    #1;

    if (imm != 32'd8) $error("IMM_B positive 8 failed: expected 32'd8, got %0d", imm);

    instr = 32'b0;

    instr[31] = 32'b1;
    instr[7] = 1'b1;
    instr[30:25] = 6'b111111;
    instr[11:8] = 4'b1110;
    imm_type = IMM_B;
    #1;

    if (imm != 32'hFFFFFFFC)
      $error("IMM_B negative 32 failed: expected 32'hFFFFFFFC, got %08h", imm);

    instr = 32'b0;

    instr[31] = 1'b1;
    instr[7] = 1'b0;
    instr[30:25] = 6'b000000;
    instr[11:8] = 4'b0000;
    imm_type = IMM_B;
    #1;

    if (imm != 32'hFFFFF000)
      $error("IMM_B negative 4096 failed: expected 32'hFFFFF000, got %08h", imm);


    instr = 32'b0;
    instr[31:12] = 20'hABCDE;
    imm_type = IMM_U;
    #1;

    if (imm != 32'hABCDE000) $error("IMM_U failed: expected 32'hABCDE000, got %08h", imm);

    instr = 32'b0;
    instr[31:12] = 20'h00001;
    imm_type = IMM_U;
    #1;

    if (imm != 32'h00001000) $error("IMM_U failed: expected 32'h00001000, got %08h", imm);

    instr = 32'b0;
    instr[31:12] = 20'hFFFFF;
    imm_type = IMM_U;
    #1;

    if (imm != 32'hFFFFF000) $error("IMM_U failed: expected 32'hFFFFF000, got %08h", imm);

  end

endmodule
