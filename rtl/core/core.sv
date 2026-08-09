module core #(
    parameter string IMEM_INIT_FILE = ""
)(
    input logic clk,
    input logic rst,
    input logic [31:0] bus_read_data,
    input logic cpu_irq,

    output logic [31:0] debug_pc,
    output logic [31:0] debug_instr,

    output logic [31:0] bus_addr,
    output logic bus_read_en,
    output logic bus_write_en,
    output logic [31:0] bus_write_data,
    output logic [3:0] bus_byte_en
);

  import riscv_pkg::*;

  // PC / instruction path
  logic [31:0] pc_current;
  logic [31:0] next_pc;
  logic [31:0] pc_plus_4;
  logic [31:0] instr;

  logic [31:0] branch_target;

  // Decoder outputs
  logic [4:0] rd_addr;
  logic [4:0] rs1_addr;
  logic [4:0] rs2_addr;

  alu_op_t alu_op;
  imm_type_t imm_type;
  branch_op_t branch_op;
  wb_sel_t wb_sel;
  alu_a_sel_t alu_a_sel;
  load_type_t load_type;
  store_type_t store_type;

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

  // Load signals
  logic [31:0] load_result;
  logic [7:0] load_byte;
  logic [15:0] load_half;

  // Store signals
  logic [31:0] store_write_data;
  logic [3:0]  store_byte_en;

  // CSR signals
    csr_op_t csr_op;

    logic        csr_write_en;
    logic        csr_actual_write_en;

    logic [11:0] csr_addr;
    logic [31:0] csr_write_data;
    logic [31:0] csr_read_data;

    logic [31:0] mtvec;
    logic [31:0] mepc;

    logic global_irq_enable;
    logic timer_irq_enable;
    logic timer_irq_pending;
    logic take_interrupt;

    logic        trap_enter;
    logic [31:0] trap_pc;
    logic [31:0] trap_cause;

    logic mret;
    logic ecall;

  pc pc_inst (
      .clk(clk),
      .rst(rst),
      .pc_we(1'b1),
      .next_pc(next_pc),
      .pc(pc_current)
  );

  imem #(
    .INIT_FILE(IMEM_INIT_FILE)
  ) imem_inst (
      .addr(pc_current),
      .instr(instr)
  );

  decoder decoder_inst (
      .instr(instr),

      .rd_addr(rd_addr),
      .rs1_addr(rs1_addr),
      .rs2_addr(rs2_addr),

      .alu_op(alu_op),
      .csr_op(csr_op),
      .imm_type(imm_type),
      .branch_op(branch_op),
      .wb_sel(wb_sel),
      .alu_a_sel(alu_a_sel),
      .load_type(load_type),
      .store_type(store_type),

      .reg_write_en(reg_write_en),
      .alu_src_imm(alu_src_imm),
      .mem_read_en(mem_read_en),
      .mem_write_en(mem_write_en),
      .jump_en(jump_en),
      .jump_reg_en(jump_reg_en),
      .csr_write_en(csr_write_en),
      .mret(mret),
      .ecall(ecall),
      .illegal_instr(illegal_instr)
  );

  regfile regfile_inst (
      .clk(clk),
      .we(reg_write_en && !illegal_instr && !ecall),
      .rs1_addr(rs1_addr),
      .rs2_addr(rs2_addr),
      .rd_addr(rd_addr),
      .rd_data(rd_data),
      .rs1_data(rs1_data),
      .rs2_data(rs2_data)
  );

  imm_gen imm_gen_inst (
      .instr(instr),
      .imm_type(imm_type),
      .imm(imm)
  );

  // ALU input muxes
  always_comb begin
    unique case (alu_a_sel)
      ALU_A_RS1:  alu_a = rs1_data;
      ALU_A_PC:   alu_a = pc_current;
      ALU_A_ZERO: alu_a = 32'd0;
      default:    alu_a = rs1_data;
    endcase
  end

  assign alu_b = alu_src_imm ? imm : rs2_data;

  alu alu_inst (
      .a(alu_a),
      .b(alu_b),
      .alu_op(alu_op),
      .result(alu_result)
  );

  branch_unit branch_unit_inst (
      .rs1_data(rs1_data),
      .rs2_data(rs2_data),
      .branch_op(branch_op),
      .taken(branch_taken)
  );

// Next PC logic
  assign pc_plus_4 = pc_current + 32'd4;

  always_comb begin
    if (take_interrupt || ecall || illegal_instr) begin
      next_pc = mtvec;
    end else if (mret) begin
      next_pc = mepc;
    end else if (jump_en && jump_reg_en) begin
      next_pc = (rs1_data + imm) & 32'hFFFF_FFFE;
    end else if (jump_en) begin
      next_pc = pc_current + imm;
    end else if (branch_taken) begin
      next_pc = pc_current + imm;
    end else begin
      next_pc = pc_plus_4;
    end
  end

// Writeback mux
  always_comb begin
    unique case (wb_sel)
      WB_ALU: rd_data = alu_result;
      WB_MEM: rd_data = load_result;
      WB_PC4: rd_data = pc_plus_4;
      WB_CSR: rd_data = csr_read_data;
      default: rd_data = alu_result;
    endcase
  end

// load mux
  always_comb begin
    unique case (alu_result[1:0])
        2'b00: load_byte = bus_read_data[7:0];
        2'b01: load_byte = bus_read_data[15:8];
        2'b10: load_byte = bus_read_data[23:16];
        2'b11: load_byte = bus_read_data[31:24];
    endcase
  end

  always_comb begin
    unique case (alu_result[1])
        1'b0: load_half = bus_read_data[15:0];
        1'b1: load_half = bus_read_data[31:16];
        default: load_half = 16'b0;
    endcase
  end

  always_comb begin
    unique case (load_type)
        LOAD_W: load_result = bus_read_data;

        LOAD_BU: load_result = {24'b0, load_byte};

        LOAD_B: load_result = {{24{load_byte[7]}}, load_byte};

        LOAD_H: load_result = {{16{load_half[15]}}, load_half};

        LOAD_HU: load_result = {16'b0, load_half};

        default: load_result = 32'b0;
    endcase
  end

  //store mux
  always_comb begin
      store_write_data = 32'b0;
      store_byte_en    = 4'b0000;

      unique case (store_type)
          STORE_B: begin
              unique case (alu_result[1:0])
                  2'b00: begin
                      store_write_data = {24'b0, rs2_data[7:0]};
                      store_byte_en    = 4'b0001;
                  end

                  2'b01: begin
                      store_write_data = {16'b0, rs2_data[7:0], 8'b0};
                      store_byte_en    = 4'b0010;
                  end

                  2'b10: begin
                      store_write_data = {8'b0, rs2_data[7:0], 16'b0};
                      store_byte_en    = 4'b0100;
                  end

                  2'b11: begin
                      store_write_data = {rs2_data[7:0], 24'b0};
                      store_byte_en    = 4'b1000;
                  end
              endcase
          end

          STORE_H: begin
              unique case (alu_result[1])
                  1'b0: begin
                      store_write_data = {16'b0, rs2_data[15:0]};
                      store_byte_en    = 4'b0011;
                  end

                  1'b1: begin
                      store_write_data = {rs2_data[15:0], 16'b0};
                      store_byte_en    = 4'b1100;
                  end
              endcase
          end

          STORE_W: begin
              store_write_data = rs2_data;
              store_byte_en    = 4'b1111;
          end

          default: begin
              store_write_data = 32'b0;
              store_byte_en    = 4'b0000;
          end
      endcase
  end

  // Bus connect

  assign bus_addr = alu_result;
  assign bus_read_en = mem_read_en && !illegal_instr && !ecall;
  assign bus_write_en = mem_write_en && !illegal_instr && !ecall;
  assign bus_write_data = store_write_data;
  assign bus_byte_en = store_byte_en;

  // CSR stuff

  csr_file csr_file_inst (
    .clk (clk),
    .rst (rst),
    .csr_addr (csr_addr),
    .csr_write_en (csr_actual_write_en),
    .csr_write_data (csr_write_data),
    .csr_read_data (csr_read_data),
    .timer_irq (cpu_irq),
    .trap_enter (trap_enter),
    .trap_pc (trap_pc),
    .trap_cause (trap_cause),
    .mret (mret),
    .mtvec (mtvec),
    .mepc (mepc),
    .global_irq_enable (global_irq_enable),
    .timer_irq_enable (timer_irq_enable),
    .timer_irq_pending (timer_irq_pending)
  );

  assign take_interrupt = global_irq_enable && timer_irq_enable && timer_irq_pending;

  assign trap_enter = take_interrupt || ecall || illegal_instr;
  
  always_comb begin
    if (illegal_instr) trap_pc = pc_current;
    else trap_pc = pc_plus_4;
  end

  always_comb begin
    trap_cause = 32'b0;
    if (take_interrupt) trap_cause = 32'h8000_0007;
    else if (ecall) trap_cause = 32'h0000_000B;
    else if (illegal_instr) trap_cause = 32'h0000_0002;
  end

  assign csr_addr = instr[31:20];

  always_comb begin
    unique case (csr_op)
        CSR_RW: csr_write_data = rs1_data;
        CSR_RS: csr_write_data = csr_read_data | rs1_data;
        default: csr_write_data = 32'd0;
    endcase
  end

  assign csr_actual_write_en =
    csr_write_en &&
    !((csr_op == CSR_RS) && (rs1_addr == 5'd0));


  // ------------------------------------------------------------
  // Debug outputs
  // ------------------------------------------------------------

  assign debug_pc    = pc_current;
  assign debug_instr = instr;

endmodule
