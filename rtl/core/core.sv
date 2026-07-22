module core (
    input logic clk,
    input logic rst,

    output logic [31:0] debug_pc,
    output logic [31:0] debug_instr
);

  import riscv_pkg::*;

  // PC / instruction path
  logic [31:0] pc_current;
  logic [31:0] next_pc;
  logic [31:0] pc_plus_4;
  logic [31:0] instr;

  // Decoder outputs
  logic [4:0] rd_addr;
  logic [4:0] rs1_addr;
  logic [4:0] rs2_addr;

  alu_op_t alu_op;
  imm_type_t imm_type;
  branch_op_t branch_op;
  wb_sel_t wb_sel;
  alu_a_sel_t alu_a_sel;

  logic reg_write_en;
  logic alu_src_imm;
  logic mem_read_en;
  logic mem_write_en;
  logic jump_en;
  logic jump_reg_en;
  logic illegal_instr;

  // Register file signals
  logic [31:0] rs1_data;
  logic [31:0] rs2_data;
  logic [31:0] rd_data;

  // Immediate
  logic [31:0] imm;

  // ALU signals
  logic [31:0] alu_a;
  logic [31:0] alu_b;
  logic [31:0] alu_result;

  // Branch
  logic branch_taken;

  // Data memory
  logic [31:0] dmem_read_data;

  // ------------------------------------------------------------
  // PC
  // ------------------------------------------------------------

  pc pc_inst (
      .clk(clk),
      .rst(rst),
      .pc_we(1'b1),
      .next_pc(next_pc),
      .pc(pc_current)
  );

  assign pc_plus_4 = pc_current + 32'd4;

  // For now, no branch/jump PC redirection yet.
  assign next_pc = pc_plus_4;

  // ------------------------------------------------------------
  // Instruction memory
  // ------------------------------------------------------------

  imem imem_inst (
      .addr(pc_current),
      .instr(instr)
  );

  // ------------------------------------------------------------
  // Decoder
  // ------------------------------------------------------------

  decoder decoder_inst (
      .instr(instr),

      .rd_addr(rd_addr),
      .rs1_addr(rs1_addr),
      .rs2_addr(rs2_addr),

      .alu_op(alu_op),
      .imm_type(imm_type),
      .branch_op(branch_op),
      .wb_sel(wb_sel),
      .alu_a_sel(alu_a_sel),

      .reg_write_en(reg_write_en),
      .alu_src_imm(alu_src_imm),
      .mem_read_en(mem_read_en),
      .mem_write_en(mem_write_en),
      .jump_en(jump_en),
      .jump_reg_en(jump_reg_en),
      .illegal_instr(illegal_instr)
  );

  // ------------------------------------------------------------
  // Register file
  // ------------------------------------------------------------

  regfile regfile_inst (
      .clk(clk),
      .we(reg_write_en),
      .rs1_addr(rs1_addr),
      .rs2_addr(rs2_addr),
      .rd_addr(rd_addr),
      .rd_data(rd_data),
      .rs1_data(rs1_data),
      .rs2_data(rs2_data)
  );

  // ------------------------------------------------------------
  // Immediate generator
  // ------------------------------------------------------------

  imm_gen imm_gen_inst (
      .instr(instr),
      .imm_type(imm_type),
      .imm(imm)
  );

  // ------------------------------------------------------------
  // ALU input muxes
  // ------------------------------------------------------------

  always_comb begin
    unique case (alu_a_sel)
      ALU_A_RS1:  alu_a = rs1_data;
      ALU_A_PC:   alu_a = pc_current;
      ALU_A_ZERO: alu_a = 32'd0;
      default:    alu_a = rs1_data;
    endcase
  end

  assign alu_b = alu_src_imm ? imm : rs2_data;

  // ------------------------------------------------------------
  // ALU
  // ------------------------------------------------------------

  alu alu_inst (
      .a(alu_a),
      .b(alu_b),
      .alu_op(alu_op),
      .result(alu_result)
  );

  // ------------------------------------------------------------
  // Branch unit
  // ------------------------------------------------------------

  branch_unit branch_unit_inst (
      .rs1_data(rs1_data),
      .rs2_data(rs2_data),
      .branch_op(branch_op),
      .taken(branch_taken)
  );

  // ------------------------------------------------------------
  // Data memory
  // ------------------------------------------------------------

  dmem dmem_inst (
      .clk(clk),
      .mem_read_en(mem_read_en),
      .mem_write_en(mem_write_en),
      .addr(alu_result),
      .write_data(rs2_data),
      .read_data(dmem_read_data)
  );

  // ------------------------------------------------------------
  // Writeback mux
  // ------------------------------------------------------------

  always_comb begin
    unique case (wb_sel)
      WB_ALU: rd_data = alu_result;
      WB_MEM: rd_data = dmem_read_data;
      WB_PC4: rd_data = pc_plus_4;
      WB_CSR: rd_data = 32'd0;  // placeholder for later
      default: rd_data = alu_result;
    endcase
  end

  // ------------------------------------------------------------
  // Debug outputs
  // ------------------------------------------------------------

  assign debug_pc    = pc_current;
  assign debug_instr = instr;

endmodule