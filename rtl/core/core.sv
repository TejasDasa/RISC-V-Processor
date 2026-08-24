module core #(
    parameter string IMEM_INIT_FILE = ""
)(
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] bus_read_data,
    input  logic        cpu_irq,

    output logic [31:0] debug_pc,
    output logic [31:0] debug_instr,

    output logic [31:0] bus_addr,
    output logic        bus_read_en,
    output logic        bus_write_en,
    output logic [31:0] bus_write_data,
    output logic [3:0]  bus_byte_en
);

    import riscv_pkg::*;

    // ============================================================
    // IF STAGE
    // ============================================================

    logic [31:0] pc_current;
    logic [31:0] pc_next;
    logic [31:0] if_instr;
    logic [31:0] if_pc_plus_4;

    logic        ex_redirect;
    logic [31:0] ex_redirect_pc;

    assign if_pc_plus_4 = pc_current + 32'd4;

    always_comb begin
        if (ex_redirect)
            pc_next = ex_redirect_pc;
        else
            pc_next = if_pc_plus_4;
    end

    pc pc_inst (
        .clk     (clk),
        .rst     (rst),
        .pc_we   (!load_use_hazard),
        .next_pc (pc_next),
        .pc      (pc_current)
    );

    imem #(
        .INIT_FILE(IMEM_INIT_FILE)
    ) imem_inst (
        .addr  (pc_current),
        .instr (if_instr)
    );


    // ============================================================
    // IF / ID PIPELINE REGISTER
    // ============================================================

    logic        if_id_valid;
    logic [31:0] if_id_pc;
    logic [31:0] if_id_instr;

    always_ff @(posedge clk) begin
        if (rst) begin
            if_id_valid <= 1'b0;
            if_id_pc    <= 32'b0;
            if_id_instr <= 32'h0000_0013; // NOP
        end else if (ex_redirect) begin
            // Flush younger instruction
            if_id_valid <= 1'b0;
            if_id_pc    <= 32'b0;
            if_id_instr <= 32'h0000_0013;
        end else if (load_use_hazard) begin
            // Hold IF/ID contents
            if_id_valid <= if_id_valid;
            if_id_pc    <= if_id_pc;
            if_id_instr <= if_id_instr;
        end else begin
            if_id_valid <= 1'b1;
            if_id_pc    <= pc_current;
            if_id_instr <= if_instr;
        end
    end


    // ============================================================
    // ID STAGE
    // ============================================================

    logic [4:0] id_rd_addr;
    logic [4:0] id_rs1_addr;
    logic [4:0] id_rs2_addr;

    alu_op_t      id_alu_op;
    imm_type_t    id_imm_type;
    branch_op_t   id_branch_op;
    wb_sel_t      id_wb_sel;
    alu_a_sel_t   id_alu_a_sel;
    load_type_t   id_load_type;
    store_type_t  id_store_type;
    csr_op_t      id_csr_op;

    logic id_reg_write_en;
    logic id_alu_src_imm;
    logic id_mem_read_en;
    logic id_mem_write_en;
    logic id_jump_en;
    logic id_jump_reg_en;
    logic id_csr_write_en;
    logic id_mret;
    logic id_ecall;
    logic id_illegal_instr;

    logic [31:0] id_rs1_data;
    logic [31:0] id_rs2_data;
    logic [31:0] id_imm;

    decoder decoder_inst (
        .instr            (if_id_instr),

        .rd_addr          (id_rd_addr),
        .rs1_addr         (id_rs1_addr),
        .rs2_addr         (id_rs2_addr),

        .alu_op           (id_alu_op),
        .csr_op           (id_csr_op),
        .imm_type         (id_imm_type),
        .branch_op        (id_branch_op),
        .wb_sel           (id_wb_sel),
        .alu_a_sel        (id_alu_a_sel),
        .load_type        (id_load_type),
        .store_type       (id_store_type),

        .reg_write_en     (id_reg_write_en),
        .alu_src_imm      (id_alu_src_imm),
        .mem_read_en      (id_mem_read_en),
        .mem_write_en     (id_mem_write_en),
        .jump_en          (id_jump_en),
        .jump_reg_en      (id_jump_reg_en),
        .csr_write_en     (id_csr_write_en),
        .mret             (id_mret),
        .ecall            (id_ecall),
        .illegal_instr    (id_illegal_instr)
    );

    imm_gen imm_gen_inst (
        .instr    (if_id_instr),
        .imm_type (id_imm_type),
        .imm      (id_imm)
    );


    // ============================================================
    // WB SIGNALS
    // ============================================================

    logic        wb_reg_write_en;
    logic [4:0]  wb_rd_addr;
    logic [31:0] wb_data;


    // ============================================================
    // REGISTER FILE
    // Reads in ID, writes in WB
    // ============================================================

    regfile regfile_inst (
        .clk      (clk),

        .we       (wb_reg_write_en),

        .rs1_addr (id_rs1_addr),
        .rs2_addr (id_rs2_addr),

        .rd_addr  (wb_rd_addr),
        .rd_data  (wb_data),

        .rs1_data (id_rs1_data),
        .rs2_data (id_rs2_data)
    );


    // ============================================================
    // ID / EX PIPELINE REGISTER
    // ============================================================

    logic        id_ex_valid;

    logic [31:0] id_ex_pc;
    logic [31:0] id_ex_pc_plus_4;

    logic [31:0] id_ex_rs1_data;
    logic [31:0] id_ex_rs2_data;
    logic [31:0] id_ex_imm;

    logic [4:0]  id_ex_rs1_addr;
    logic [4:0]  id_ex_rs2_addr;
    logic [4:0]  id_ex_rd_addr;

    alu_op_t      id_ex_alu_op;
    alu_a_sel_t   id_ex_alu_a_sel;
    logic         id_ex_alu_src_imm;

    branch_op_t   id_ex_branch_op;

    wb_sel_t      id_ex_wb_sel;
    logic         id_ex_reg_write_en;

    logic         id_ex_mem_read_en;
    logic         id_ex_mem_write_en;
    load_type_t   id_ex_load_type;
    store_type_t  id_ex_store_type;

    logic         id_ex_jump_en;
    logic         id_ex_jump_reg_en;

    csr_op_t      id_ex_csr_op;
    logic         id_ex_csr_write_en;
    logic [11:0]  id_ex_csr_addr;

    logic         id_ex_mret;
    logic         id_ex_ecall;
    logic         id_ex_illegal_instr;


    always_ff @(posedge clk) begin
        if (rst) begin
            id_ex_valid <= 1'b0;

            id_ex_pc          <= 32'b0;
            id_ex_pc_plus_4   <= 32'b0;

            id_ex_rs1_data    <= 32'b0;
            id_ex_rs2_data    <= 32'b0;
            id_ex_imm         <= 32'b0;

            id_ex_rs1_addr    <= 5'b0;
            id_ex_rs2_addr    <= 5'b0;
            id_ex_rd_addr     <= 5'b0;

            id_ex_reg_write_en <= 1'b0;
            id_ex_mem_read_en  <= 1'b0;
            id_ex_mem_write_en <= 1'b0;

            id_ex_jump_en      <= 1'b0;
            id_ex_jump_reg_en  <= 1'b0;

            id_ex_csr_write_en <= 1'b0;

            id_ex_mret          <= 1'b0;
            id_ex_ecall         <= 1'b0;
            id_ex_illegal_instr <= 1'b0;

            id_ex_csr_addr <= 12'b0;

        end else if (ex_redirect) begin

            // Flush instruction currently in ID
            id_ex_valid <= 1'b0;

            id_ex_reg_write_en <= 1'b0;
            id_ex_mem_read_en  <= 1'b0;
            id_ex_mem_write_en <= 1'b0;

            id_ex_jump_en      <= 1'b0;
            id_ex_jump_reg_en  <= 1'b0;

            id_ex_csr_write_en <= 1'b0;

            id_ex_mret          <= 1'b0;
            id_ex_ecall         <= 1'b0;
            id_ex_illegal_instr <= 1'b0;

        end else if (load_use_hazard) begin
            id_ex_valid <= 1'b0;

            id_ex_reg_write_en <= 1'b0;
            id_ex_mem_read_en  <= 1'b0;
            id_ex_mem_write_en <= 1'b0;

            id_ex_jump_en      <= 1'b0;
            id_ex_jump_reg_en  <= 1'b0;

            id_ex_csr_write_en <= 1'b0;

            id_ex_mret          <= 1'b0;
            id_ex_ecall         <= 1'b0;
            id_ex_illegal_instr <= 1'b0;
        end else begin

            id_ex_valid <= if_id_valid;

            id_ex_pc        <= if_id_pc;
            id_ex_pc_plus_4 <= if_id_pc + 32'd4;

            id_ex_rs1_data <= id_rs1_data_bypassed;
            id_ex_rs2_data <= id_rs2_data_bypassed;
            id_ex_imm      <= id_imm;

            id_ex_rs1_addr <= id_rs1_addr;
            id_ex_rs2_addr <= id_rs2_addr;
            id_ex_rd_addr  <= id_rd_addr;

            id_ex_alu_op      <= id_alu_op;
            id_ex_alu_a_sel   <= id_alu_a_sel;
            id_ex_alu_src_imm <= id_alu_src_imm;

            id_ex_branch_op <= id_branch_op;

            id_ex_wb_sel       <= id_wb_sel;
            id_ex_reg_write_en <= id_reg_write_en;

            id_ex_mem_read_en  <= id_mem_read_en;
            id_ex_mem_write_en <= id_mem_write_en;

            id_ex_load_type  <= id_load_type;
            id_ex_store_type <= id_store_type;

            id_ex_jump_en     <= id_jump_en;
            id_ex_jump_reg_en <= id_jump_reg_en;

            id_ex_csr_op       <= id_csr_op;
            id_ex_csr_write_en <= id_csr_write_en;

            id_ex_csr_addr <= if_id_instr[31:20];

            id_ex_mret          <= id_mret;
            id_ex_ecall         <= id_ecall;
            id_ex_illegal_instr <= id_illegal_instr;
        end
    end


    // ============================================================
    // EX STAGE
    // ============================================================

    logic [31:0] ex_alu_a;
    logic [31:0] ex_alu_b;
    logic [31:0] ex_alu_result;

    logic ex_branch_taken;

    always_comb begin
        unique case (id_ex_alu_a_sel)
            ALU_A_RS1:
                ex_alu_a = ex_rs1_forwarded;

            ALU_A_PC:
                ex_alu_a = id_ex_pc;

            ALU_A_ZERO:
                ex_alu_a = 32'd0;

            default:
                ex_alu_a = ex_rs1_forwarded;
        endcase
    end

    assign ex_alu_b =
        id_ex_alu_src_imm
            ? id_ex_imm
            : ex_rs2_forwarded;

    alu alu_inst (
        .a      (ex_alu_a),
        .b      (ex_alu_b),
        .alu_op (id_ex_alu_op),
        .result (ex_alu_result)
    );

    branch_unit branch_unit_inst (
        .rs1_data  (ex_rs1_forwarded),
        .rs2_data  (ex_rs2_forwarded),
        .branch_op  (id_ex_branch_op),
        .taken      (ex_branch_taken)
    );


    // ============================================================
    // CSR FILE
    // ============================================================

    logic [31:0] csr_read_data;
    logic [31:0] csr_write_data;
    logic        csr_actual_write_en;

    logic [31:0] mtvec;
    logic [31:0] mepc;

    logic global_irq_enable;
    logic timer_irq_enable;
    logic timer_irq_pending;

    logic        trap_enter;
    logic [31:0] trap_pc;
    logic [31:0] trap_cause;


    always_comb begin
        unique case (id_ex_csr_op)
            CSR_RW:
                csr_write_data = id_ex_rs1_data;

            CSR_RS:
                csr_write_data =
                    csr_read_data | id_ex_rs1_data;

            default:
                csr_write_data = 32'd0;
        endcase
    end


    assign csr_actual_write_en =
        id_ex_valid &&
        id_ex_csr_write_en &&
        !id_ex_ecall &&
        !id_ex_illegal_instr &&
        !((id_ex_csr_op == CSR_RS) &&
          (id_ex_rs1_addr == 5'd0));


    csr_file csr_file_inst (
        .clk                  (clk),
        .rst                  (rst),

        .csr_addr             (id_ex_csr_addr),
        .csr_write_en         (csr_actual_write_en),
        .csr_write_data       (csr_write_data),
        .csr_read_data        (csr_read_data),

        .timer_irq            (cpu_irq),

        .trap_enter           (trap_enter),
        .trap_pc              (trap_pc),
        .trap_cause           (trap_cause),

        .mret                 (id_ex_valid && id_ex_mret),

        .mtvec                (mtvec),
        .mepc                 (mepc),

        .global_irq_enable    (global_irq_enable),
        .timer_irq_enable     (timer_irq_enable),
        .timer_irq_pending    (timer_irq_pending)
    );


    // ============================================================
    // EX REDIRECT / CONTROL FLOW
    //
    // NOTE:
    // Timer interrupts are intentionally deferred for initial
    // pipeline bring-up.
    // ============================================================

    logic ex_take_branch;
    logic ex_take_jump;
    logic ex_take_jalr;
    logic ex_take_mret;
    logic ex_take_exception;

    assign ex_take_branch =
        id_ex_valid &&
        ex_branch_taken;

    assign ex_take_jump =
        id_ex_valid &&
        id_ex_jump_en &&
        !id_ex_jump_reg_en;

    assign ex_take_jalr =
        id_ex_valid &&
        id_ex_jump_en &&
        id_ex_jump_reg_en;

    assign ex_take_mret =
        id_ex_valid &&
        id_ex_mret;

    assign ex_take_exception =
        id_ex_valid &&
        (id_ex_ecall || id_ex_illegal_instr);


    always_comb begin
        ex_redirect    = 1'b0;
        ex_redirect_pc = 32'b0;

        if (ex_take_exception) begin
            ex_redirect    = 1'b1;
            ex_redirect_pc = mtvec;

        end else if (ex_take_mret) begin
            ex_redirect    = 1'b1;
            ex_redirect_pc = mepc;

        end else if (ex_take_jalr) begin
            ex_redirect    = 1'b1;
            ex_redirect_pc =
                (ex_rs1_forwarded + id_ex_imm)
                & 32'hFFFF_FFFE;

        end else if (ex_take_jump) begin
            ex_redirect    = 1'b1;
            ex_redirect_pc =
                id_ex_pc + id_ex_imm;

        end else if (ex_take_branch) begin
            ex_redirect    = 1'b1;
            ex_redirect_pc =
                id_ex_pc + id_ex_imm;
        end
    end

    // ============================================================
    // FORWARDING
    // ============================================================

    logic [31:0] ex_rs1_forwarded;
    logic [31:0] ex_rs2_forwarded;

    always_comb begin
        ex_rs1_forwarded = id_ex_rs1_data;
        ex_rs2_forwarded = id_ex_rs2_data;

        // MEM/WB forwarding
        if (mem_wb_valid &&
            mem_wb_reg_write_en &&
            (mem_wb_rd_addr != 5'd0) &&
            (mem_wb_rd_addr == id_ex_rs1_addr)) begin
            ex_rs1_forwarded = wb_data;
        end

        if (mem_wb_valid &&
            mem_wb_reg_write_en &&
            (mem_wb_rd_addr != 5'd0) &&
            (mem_wb_rd_addr == id_ex_rs2_addr)) begin
            ex_rs2_forwarded = wb_data;
        end

        // EX/MEM forwarding takes priority because it's newer
        if (ex_mem_valid &&
            ex_mem_reg_write_en &&
            (ex_mem_rd_addr != 5'd0) &&
            (ex_mem_rd_addr == id_ex_rs1_addr) &&
            (ex_mem_wb_sel != WB_MEM)) begin
            ex_rs1_forwarded =
                (ex_mem_wb_sel == WB_PC4) ?
                    ex_mem_pc_plus_4 :
                    (ex_mem_wb_sel == WB_CSR) ?
                        ex_mem_csr_read_data :
                        ex_mem_alu_result;
        end

        if (ex_mem_valid &&
            ex_mem_reg_write_en &&
            (ex_mem_rd_addr != 5'd0) &&
            (ex_mem_rd_addr == id_ex_rs2_addr) &&
            (ex_mem_wb_sel != WB_MEM)) begin
            ex_rs2_forwarded =
                (ex_mem_wb_sel == WB_PC4) ?
                    ex_mem_pc_plus_4 :
                    (ex_mem_wb_sel == WB_CSR) ?
                        ex_mem_csr_read_data :
                        ex_mem_alu_result;
        end
    end


    // ============================================================
    // EXCEPTION SIGNALS
    // ============================================================

    assign trap_enter =
        id_ex_valid &&
        (id_ex_ecall || id_ex_illegal_instr);

    always_comb begin
        trap_pc = 32'b0;

        if (id_ex_ecall)
            trap_pc = id_ex_pc_plus_4;

        else if (id_ex_illegal_instr)
            trap_pc = id_ex_pc;
    end

    always_comb begin
        trap_cause = 32'b0;

        if (id_ex_ecall)
            trap_cause = 32'h0000_000B;

        else if (id_ex_illegal_instr)
            trap_cause = 32'h0000_0002;
    end


    // ============================================================
    // EX / MEM PIPELINE REGISTER
    // ============================================================

    logic        ex_mem_valid;

    logic [31:0] ex_mem_alu_result;
    logic [31:0] ex_mem_rs2_data;
    logic [31:0] ex_mem_pc_plus_4;

    logic [31:0] ex_mem_csr_read_data;

    logic [4:0]  ex_mem_rd_addr;

    logic         ex_mem_reg_write_en;
    wb_sel_t      ex_mem_wb_sel;

    logic         ex_mem_mem_read_en;
    logic         ex_mem_mem_write_en;

    load_type_t   ex_mem_load_type;
    store_type_t  ex_mem_store_type;


    always_ff @(posedge clk) begin
        if (rst) begin
            ex_mem_valid <= 1'b0;

            ex_mem_alu_result <= 32'b0;
            ex_mem_rs2_data   <= 32'b0;
            ex_mem_pc_plus_4  <= 32'b0;

            ex_mem_csr_read_data <= 32'b0;

            ex_mem_rd_addr <= 5'b0;

            ex_mem_reg_write_en <= 1'b0;
            ex_mem_mem_read_en  <= 1'b0;
            ex_mem_mem_write_en <= 1'b0;

        end else begin

            ex_mem_valid <=
                id_ex_valid &&
                !id_ex_ecall &&
                !id_ex_illegal_instr;

            ex_mem_alu_result <= ex_alu_result;
            ex_mem_rs2_data   <= ex_rs2_forwarded;
            ex_mem_pc_plus_4  <= id_ex_pc_plus_4;

            ex_mem_csr_read_data <= csr_read_data;

            ex_mem_rd_addr <= id_ex_rd_addr;

            ex_mem_reg_write_en <=
                id_ex_valid &&
                !id_ex_ecall &&
                !id_ex_illegal_instr &&
                id_ex_reg_write_en;

            ex_mem_wb_sel <=
                id_ex_wb_sel;

            ex_mem_mem_read_en <=
                id_ex_valid &&
                !id_ex_ecall &&
                !id_ex_illegal_instr &&
                id_ex_mem_read_en;

            ex_mem_mem_write_en <=
                id_ex_valid &&
                !id_ex_ecall &&
                !id_ex_illegal_instr &&
                id_ex_mem_write_en;

            ex_mem_load_type <=
                id_ex_load_type;

            ex_mem_store_type <=
                id_ex_store_type;
        end
    end


    // ============================================================
    // MEM STAGE
    // ============================================================

    logic [7:0]  mem_load_byte;
    logic [15:0] mem_load_half;
    logic [31:0] mem_load_result;

    logic [31:0] mem_store_write_data;
    logic [3:0]  mem_store_byte_en;


    // ------------------------------------------------------------
    // Load byte selection
    // ------------------------------------------------------------

    always_comb begin
        unique case (ex_mem_alu_result[1:0])
            2'b00:
                mem_load_byte = bus_read_data[7:0];

            2'b01:
                mem_load_byte = bus_read_data[15:8];

            2'b10:
                mem_load_byte = bus_read_data[23:16];

            2'b11:
                mem_load_byte = bus_read_data[31:24];
        endcase
    end


    // ------------------------------------------------------------
    // Load halfword selection
    // ------------------------------------------------------------

    always_comb begin
        unique case (ex_mem_alu_result[1])
            1'b0:
                mem_load_half = bus_read_data[15:0];

            1'b1:
                mem_load_half = bus_read_data[31:16];

            default:
                mem_load_half = 16'b0;
        endcase
    end


    // ------------------------------------------------------------
    // Load extension
    // ------------------------------------------------------------

    always_comb begin
        unique case (ex_mem_load_type)

            LOAD_W:
                mem_load_result =
                    bus_read_data;

            LOAD_BU:
                mem_load_result =
                    {24'b0, mem_load_byte};

            LOAD_B:
                mem_load_result =
                    {{24{mem_load_byte[7]}},
                     mem_load_byte};

            LOAD_H:
                mem_load_result =
                    {{16{mem_load_half[15]}},
                     mem_load_half};

            LOAD_HU:
                mem_load_result =
                    {16'b0, mem_load_half};

            default:
                mem_load_result =
                    32'b0;
        endcase
    end


    // ------------------------------------------------------------
    // Store formatting
    // ------------------------------------------------------------

    always_comb begin

        mem_store_write_data = 32'b0;
        mem_store_byte_en    = 4'b0000;

        unique case (ex_mem_store_type)

            STORE_B: begin
                unique case (ex_mem_alu_result[1:0])

                    2'b00: begin
                        mem_store_write_data =
                            {24'b0,
                             ex_mem_rs2_data[7:0]};

                        mem_store_byte_en =
                            4'b0001;
                    end

                    2'b01: begin
                        mem_store_write_data =
                            {16'b0,
                             ex_mem_rs2_data[7:0],
                             8'b0};

                        mem_store_byte_en =
                            4'b0010;
                    end

                    2'b10: begin
                        mem_store_write_data =
                            {8'b0,
                             ex_mem_rs2_data[7:0],
                             16'b0};

                        mem_store_byte_en =
                            4'b0100;
                    end

                    2'b11: begin
                        mem_store_write_data =
                            {ex_mem_rs2_data[7:0],
                             24'b0};

                        mem_store_byte_en =
                            4'b1000;
                    end

                endcase
            end


            STORE_H: begin
                unique case (ex_mem_alu_result[1])

                    1'b0: begin
                        mem_store_write_data =
                            {16'b0,
                             ex_mem_rs2_data[15:0]};

                        mem_store_byte_en =
                            4'b0011;
                    end

                    1'b1: begin
                        mem_store_write_data =
                            {ex_mem_rs2_data[15:0],
                             16'b0};

                        mem_store_byte_en =
                            4'b1100;
                    end

                endcase
            end


            STORE_W: begin
                mem_store_write_data =
                    ex_mem_rs2_data;

                mem_store_byte_en =
                    4'b1111;
            end


            default: begin
                mem_store_write_data =
                    32'b0;

                mem_store_byte_en =
                    4'b0000;
            end

        endcase
    end


    // ============================================================
    // BUS OUTPUTS
    // ============================================================

    assign bus_addr =
        ex_mem_alu_result;

    assign bus_read_en =
        ex_mem_valid &&
        ex_mem_mem_read_en;

    assign bus_write_en =
        ex_mem_valid &&
        ex_mem_mem_write_en;

    assign bus_write_data =
        mem_store_write_data;

    assign bus_byte_en =
        mem_store_byte_en;


    // ============================================================
    // MEM / WB PIPELINE REGISTER
    // ============================================================

    logic        mem_wb_valid;

    logic [31:0] mem_wb_alu_result;
    logic [31:0] mem_wb_load_result;
    logic [31:0] mem_wb_pc_plus_4;
    logic [31:0] mem_wb_csr_read_data;

    logic [4:0]  mem_wb_rd_addr;

    logic         mem_wb_reg_write_en;
    wb_sel_t      mem_wb_wb_sel;

    logic [31:0] id_rs1_data_bypassed;
    logic [31:0] id_rs2_data_bypassed;

    always_comb begin
        id_rs1_data_bypassed = id_rs1_data;
        id_rs2_data_bypassed = id_rs2_data;

        if (wb_reg_write_en &&
            (wb_rd_addr != 5'd0) &&
            (wb_rd_addr == id_rs1_addr)) begin
            id_rs1_data_bypassed = wb_data;
        end

        if (wb_reg_write_en &&
            (wb_rd_addr != 5'd0) &&
            (wb_rd_addr == id_rs2_addr)) begin
            id_rs2_data_bypassed = wb_data;
        end
    end


    always_ff @(posedge clk) begin
        if (rst) begin

            mem_wb_valid <= 1'b0;

            mem_wb_alu_result    <= 32'b0;
            mem_wb_load_result   <= 32'b0;
            mem_wb_pc_plus_4     <= 32'b0;
            mem_wb_csr_read_data <= 32'b0;

            mem_wb_rd_addr <= 5'b0;

            mem_wb_reg_write_en <= 1'b0;

        end else begin

            mem_wb_valid <= ex_mem_valid;

            mem_wb_alu_result <=
                ex_mem_alu_result;

            mem_wb_load_result <=
                mem_load_result;

            mem_wb_pc_plus_4 <=
                ex_mem_pc_plus_4;

            mem_wb_csr_read_data <=
                ex_mem_csr_read_data;

            mem_wb_rd_addr <=
                ex_mem_rd_addr;

            mem_wb_reg_write_en <=
                ex_mem_reg_write_en;

            mem_wb_wb_sel <=
                ex_mem_wb_sel;
        end
    end


    // ============================================================
    // WB STAGE
    // ============================================================

    always_comb begin
        unique case (mem_wb_wb_sel)

            WB_ALU:
                wb_data =
                    mem_wb_alu_result;

            WB_MEM:
                wb_data =
                    mem_wb_load_result;

            WB_PC4:
                wb_data =
                    mem_wb_pc_plus_4;

            WB_CSR:
                wb_data =
                    mem_wb_csr_read_data;

            default:
                wb_data =
                    mem_wb_alu_result;
        endcase
    end


    assign wb_rd_addr =
        mem_wb_rd_addr;

    assign wb_reg_write_en =
        mem_wb_valid &&
        mem_wb_reg_write_en &&
        (mem_wb_rd_addr != 5'd0);


    // Load-Use Hazard

    logic load_use_hazard;

    assign load_use_hazard =
        id_ex_valid &&
        id_ex_mem_read_en &&
        (id_ex_rd_addr != 5'd0) &&
        (
            (id_ex_rd_addr == id_rs1_addr) ||
            (id_ex_rd_addr == id_rs2_addr)
        );

    


    // ============================================================
    // DEBUG
    // ============================================================

    assign debug_pc =
        pc_current;

    assign debug_instr =
        if_instr;

endmodule
