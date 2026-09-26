module csr_file (
    input  logic        clk,
    input  logic        rst,

    // Software CSR access
    input  logic [11:0] csr_addr,
    input  logic        csr_write_en,
    input  logic [31:0] csr_write_data,
    output logic [31:0] csr_read_data,
    output logic        csr_addr_valid,   // csr_addr is implemented

    // Hardware interrupt input
    input  logic        timer_irq,

    // Trap entry
    input  logic        trap_enter,
    input  logic [31:0] trap_pc,
    input  logic [31:0] trap_cause,

    // Trap return
    input  logic        mret,

    // Core-visible CSR outputs
    output logic [31:0] mtvec,
    output logic [31:0] mepc,

    output logic        global_irq_enable,
    output logic        timer_irq_enable,
    output logic        timer_irq_pending
);

  // ------------------------------------------------------------
  // CSR addresses
  // ------------------------------------------------------------

  localparam logic [11:0] CSR_MSTATUS = 12'h300;
  localparam logic [11:0] CSR_MIE     = 12'h304;
  localparam logic [11:0] CSR_MTVEC   = 12'h305;
  localparam logic [11:0] CSR_MSCRATCH = 12'h340;
  localparam logic [11:0] CSR_MEPC    = 12'h341;
  localparam logic [11:0] CSR_MCAUSE  = 12'h342;
  localparam logic [11:0] CSR_MTVAL   = 12'h343;
  localparam logic [11:0] CSR_MIP     = 12'h344;

  // ------------------------------------------------------------
  // Internal CSR registers
  // ------------------------------------------------------------

  logic [31:0] mstatus;
  logic [31:0] mie;
  logic [31:0] mcause;
  logic [31:0] mscratch;

  // mstatus is WARL: only MIE (bit 3) and MPIE (bit 7) are stored.
  // MPP (bits 12:11) is hardwired to M-mode (2'b11), the only
  // privilege mode implemented.
  localparam logic [31:0] MSTATUS_WMASK = 32'h0000_0088;
  localparam logic [31:0] MSTATUS_MPP_M = 32'h0000_1800;

  // ------------------------------------------------------------
  // Important CSR bits
  // ------------------------------------------------------------

  assign global_irq_enable =
      mstatus[3];   // MIE

  assign timer_irq_enable =
      mie[7];       // MTIE

  assign timer_irq_pending =
      timer_irq;    // MTIP mirrors hardware timer IRQ

  // ------------------------------------------------------------
  // Implemented CSR addresses. Any other address is an illegal
  // instruction (raised by the core in EX).
  // ------------------------------------------------------------

  always_comb begin
    unique case (csr_addr)
      CSR_MSTATUS,
      CSR_MIE,
      CSR_MTVEC,
      CSR_MSCRATCH,
      CSR_MEPC,
      CSR_MCAUSE,
      CSR_MTVAL,
      CSR_MIP:  csr_addr_valid = 1'b1;
      default:  csr_addr_valid = 1'b0;
    endcase
  end

  // ------------------------------------------------------------
  // CSR read mux
  // ------------------------------------------------------------

  always_comb begin
    csr_read_data = 32'b0;

    unique case (csr_addr)
      CSR_MSTATUS:  csr_read_data = mstatus | MSTATUS_MPP_M;
      CSR_MSCRATCH: csr_read_data = mscratch;
      CSR_MTVAL:    csr_read_data = 32'b0;   // read-only zero
      CSR_MIE:     csr_read_data = mie;
      CSR_MTVEC:   csr_read_data = mtvec;
      CSR_MEPC:    csr_read_data = mepc;
      CSR_MCAUSE:  csr_read_data = mcause;

      CSR_MIP: begin
        csr_read_data = 32'b0;
        csr_read_data[7] = timer_irq_pending;
      end

      default: begin
        csr_read_data = 32'b0;
      end
    endcase
  end

  // ------------------------------------------------------------
  // CSR state updates
  // ------------------------------------------------------------

  always_ff @(posedge clk) begin
    if (rst) begin
      mstatus <= 32'b0;
      mie     <= 32'b0;
      mtvec   <= 32'b0;
      mepc    <= 32'b0;
      mcause  <= 32'b0;
      mscratch <= 32'b0;

    end else begin

      // --------------------------------------------------------
      // Software CSR writes
      // --------------------------------------------------------

      if (csr_write_en) begin
        unique case (csr_addr)

          CSR_MSTATUS: begin
            mstatus <= csr_write_data & MSTATUS_WMASK;
          end

          CSR_MIE: begin
            mie <= csr_write_data;
          end

          CSR_MTVEC: begin
            mtvec <= csr_write_data;
          end

          CSR_MEPC: begin
            mepc <= csr_write_data;
          end

          CSR_MCAUSE: begin
            mcause <= csr_write_data;
          end

          CSR_MSCRATCH: begin
            mscratch <= csr_write_data;
          end

          // mtval is read-only zero (writes ignored).
          CSR_MTVAL: begin
          end

          // MIP is read-only for now.
          CSR_MIP: begin
          end

          default: begin
          end

        endcase
      end

      // --------------------------------------------------------
      // Hardware trap entry
      //
      // Stack the interrupt enable: MPIE <= MIE, MIE <= 0.
      // --------------------------------------------------------

      if (trap_enter) begin
        mepc        <= trap_pc;
        mcause      <= trap_cause;
        mstatus[7]  <= mstatus[3];
        mstatus[3]  <= 1'b0;
      end

      // --------------------------------------------------------
      // MRET
      //
      // Unstack the interrupt enable: MIE <= MPIE, MPIE <= 1.
      // --------------------------------------------------------

      if (mret) begin
        mstatus[3] <= mstatus[7];
        mstatus[7] <= 1'b1;
      end

    end
  end

endmodule
