module csr_file_tb;

  logic clk;
  logic rst;

  logic [11:0] csr_addr;
  logic        csr_write_en;
  logic [31:0] csr_write_data;
  logic [31:0] csr_read_data;

  logic timer_irq;

  logic        trap_enter;
  logic [31:0] trap_pc;
  logic [31:0] trap_cause;

  logic mret;

  logic [31:0] mtvec;
  logic [31:0] mepc;

  logic global_irq_enable;
  logic timer_irq_enable;
  logic timer_irq_pending;

  int failures;

  localparam logic [11:0] CSR_MSTATUS = 12'h300;
  localparam logic [11:0] CSR_MIE     = 12'h304;
  localparam logic [11:0] CSR_MTVEC   = 12'h305;
  localparam logic [11:0] CSR_MEPC    = 12'h341;
  localparam logic [11:0] CSR_MCAUSE  = 12'h342;
  localparam logic [11:0] CSR_MIP     = 12'h344;

  csr_file dut (
      .clk               (clk),
      .rst               (rst),

      .csr_addr          (csr_addr),
      .csr_write_en      (csr_write_en),
      .csr_write_data    (csr_write_data),
      .csr_read_data     (csr_read_data),

      .timer_irq         (timer_irq),

      .trap_enter        (trap_enter),
      .trap_pc           (trap_pc),
      .trap_cause        (trap_cause),

      .mret              (mret),

      .mtvec             (mtvec),
      .mepc              (mepc),

      .global_irq_enable (global_irq_enable),
      .timer_irq_enable  (timer_irq_enable),
      .timer_irq_pending (timer_irq_pending)
  );

  task automatic check_eq32(
      input string test_name,
      input logic [31:0] actual,
      input logic [31:0] expected
  );
    if (actual !== expected) begin
      $error(
          "%s failed: expected 0x%08h, got 0x%08h",
          test_name,
          expected,
          actual
      );
      failures++;
    end
  endtask

  task automatic check_eq1(
      input string test_name,
      input logic actual,
      input logic expected
  );
    if (actual !== expected) begin
      $error(
          "%s failed: expected %0b, got %0b",
          test_name,
          expected,
          actual
      );
      failures++;
    end
  endtask

  task automatic write_csr(
      input logic [11:0] address,
      input logic [31:0] value
  );
    csr_addr       = address;
    csr_write_data = value;
    csr_write_en   = 1'b1;

    @(posedge clk);
    #1;

    csr_write_en = 1'b0;
  endtask

  task automatic read_csr(
      input logic [11:0] address,
      input logic [31:0] expected,
      input string test_name
  );
    csr_addr = address;
    #1;

    check_eq32(
        test_name,
        csr_read_data,
        expected
    );
  endtask

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    failures       = 0;

    rst            = 1'b1;
    csr_addr       = 12'b0;
    csr_write_en   = 1'b0;
    csr_write_data = 32'b0;

    timer_irq      = 1'b0;

    trap_enter     = 1'b0;
    trap_pc        = 32'b0;
    trap_cause     = 32'b0;

    mret           = 1'b0;

    // ----------------------------------------------------------
    // Reset
    // ----------------------------------------------------------

    @(posedge clk);
    #1;

    check_eq32("mtvec reset", mtvec, 32'd0);
    check_eq32("mepc reset", mepc, 32'd0);

    check_eq1(
        "global irq disabled after reset",
        global_irq_enable,
        1'b0
    );

    check_eq1(
        "timer irq disabled after reset",
        timer_irq_enable,
        1'b0
    );

    check_eq1(
        "timer irq not pending after reset",
        timer_irq_pending,
        1'b0
    );

    rst = 1'b0;

    // ----------------------------------------------------------
    // MTVEC read/write
    // ----------------------------------------------------------

    write_csr(
        CSR_MTVEC,
        32'h0000_0200
    );

    check_eq32(
        "mtvec output after write",
        mtvec,
        32'h0000_0200
    );

    read_csr(
        CSR_MTVEC,
        32'h0000_0200,
        "mtvec readback"
    );

    // ----------------------------------------------------------
    // MSTATUS.MIE
    //
    // bit 3 = global machine interrupt enable
    // ----------------------------------------------------------

    write_csr(
        CSR_MSTATUS,
        32'h0000_0008
    );

    check_eq1(
        "global irq enabled",
        global_irq_enable,
        1'b1
    );

    read_csr(
        CSR_MSTATUS,
        32'h0000_0008,
        "mstatus readback"
    );

    // ----------------------------------------------------------
    // MIE.MTIE
    //
    // bit 7 = machine timer interrupt enable
    // ----------------------------------------------------------

    write_csr(
        CSR_MIE,
        32'h0000_0080
    );

    check_eq1(
        "timer irq enabled",
        timer_irq_enable,
        1'b1
    );

    read_csr(
        CSR_MIE,
        32'h0000_0080,
        "mie readback"
    );

    // ----------------------------------------------------------
    // MIP.MTIP mirrors timer_irq
    // ----------------------------------------------------------

    timer_irq = 1'b1;
    #1;

    check_eq1(
        "timer irq pending high",
        timer_irq_pending,
        1'b1
    );

    read_csr(
        CSR_MIP,
        32'h0000_0080,
        "mip shows MTIP"
    );

    timer_irq = 1'b0;
    #1;

    check_eq1(
        "timer irq pending clears",
        timer_irq_pending,
        1'b0
    );

    read_csr(
        CSR_MIP,
        32'h0000_0000,
        "mip clears MTIP"
    );

    // ----------------------------------------------------------
    // Direct MEPC software write
    // ----------------------------------------------------------

    write_csr(
        CSR_MEPC,
        32'h0000_0120
    );

    check_eq32(
        "mepc software write",
        mepc,
        32'h0000_0120
    );

    // ----------------------------------------------------------
    // Trap entry
    //
    // Should:
    //   mepc      = trap_pc
    //   mcause    = trap_cause
    //   mstatus.MIE = 0
    // ----------------------------------------------------------

    trap_pc    = 32'h0000_0080;
    trap_cause = 32'h8000_0007;
    trap_enter = 1'b1;

    @(posedge clk);
    #1;

    trap_enter = 1'b0;

    check_eq32(
        "mepc captured trap PC",
        mepc,
        32'h0000_0080
    );

    read_csr(
        CSR_MCAUSE,
        32'h8000_0007,
        "mcause captured timer interrupt"
    );

    check_eq1(
        "global irq disabled during trap",
        global_irq_enable,
        1'b0
    );

    // ----------------------------------------------------------
    // MRET
    //
    // Current simplified design restores MIE directly to 1.
    // ----------------------------------------------------------

    mret = 1'b1;

    @(posedge clk);
    #1;

    mret = 1'b0;

    check_eq1(
        "global irq enabled after mret",
        global_irq_enable,
        1'b1
    );

    // MEPC should remain unchanged.
    check_eq32(
        "mepc preserved after mret",
        mepc,
        32'h0000_0080
    );

    // ----------------------------------------------------------
    // Unknown CSR reads return zero
    // ----------------------------------------------------------

    read_csr(
        12'hFFF,
        32'h0000_0000,
        "unknown CSR read"
    );

    // ----------------------------------------------------------
    // Result
    // ----------------------------------------------------------

    if (failures == 0) begin
      $display("PASS: all CSR file tests passed");
    end else begin
      $fatal(
          1,
          "FAIL: csr_file_tb had %0d failure(s)",
          failures
      );
    end

    $finish;
  end

endmodule
