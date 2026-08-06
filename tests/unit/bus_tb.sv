module bus_tb;

  localparam logic [31:0] DMEM_BASE    = 32'h0001_0000;
  localparam logic [31:0] UART_TX_ADDR = 32'h1000_0000;

  logic clk;
  logic rst;

  logic [31:0] cpu_addr;
  logic        cpu_read_en;
  logic        cpu_write_en;
  logic [31:0] cpu_write_data;
  logic [3:0]  cpu_byte_en;

  logic [31:0] cpu_read_data;

  logic       uart_write_valid;
  logic [7:0] uart_write_data;

  logic uart_busy;

  int failures;

  bus #(
      .DMEM_INIT_FILE("")
  ) dut (
      .clk            (clk),
      .rst            (rst),

      .cpu_addr       (cpu_addr),
      .cpu_read_en    (cpu_read_en),
      .cpu_write_en   (cpu_write_en),
      .cpu_write_data (cpu_write_data),
      .cpu_byte_en    (cpu_byte_en),

      .cpu_read_data  (cpu_read_data),

      .uart_write_valid  (uart_write_valid),
      .uart_write_data   (uart_write_data),
      .uart_busy (uart_busy)
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

  task automatic check_eq8(
      input string test_name,
      input logic [7:0] actual,
      input logic [7:0] expected
  );
    if (actual !== expected) begin
      $error(
          "%s failed: expected 0x%02h, got 0x%02h",
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

  task automatic bus_write(
      input logic [31:0] address,
      input logic [31:0] value,
      input logic [3:0]  enables
  );
    cpu_addr       = address;
    cpu_write_data = value;
    cpu_byte_en    = enables;
    cpu_read_en    = 1'b0;
    cpu_write_en   = 1'b1;

    @(posedge clk);
    #1;

    cpu_write_en   = 1'b0;
    cpu_byte_en    = 4'b0000;
  endtask

  task automatic bus_read(
      input logic [31:0] address,
      output logic [31:0] value
  );
    cpu_addr       = address;
    cpu_read_en    = 1'b1;
    cpu_write_en   = 1'b0;
    cpu_byte_en    = 4'b0000;

    #1;
    value = cpu_read_data;

    cpu_read_en = 1'b0;
  endtask

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    logic [31:0] read_value;

    failures      = 0;
    rst           = 1'b1;
    cpu_addr      = 32'b0;
    cpu_read_en   = 1'b0;
    cpu_write_en  = 1'b0;
    cpu_write_data = 32'b0;
    cpu_byte_en   = 4'b0000;

    @(posedge clk);
    #1;

    rst = 1'b0;

    // ----------------------------------------------------------
    // Full RAM word write/read
    // ----------------------------------------------------------

    bus_write(
        DMEM_BASE,
        32'h1122_3344,
        4'b1111
    );

    bus_read(DMEM_BASE, read_value);

    check_eq32(
        "RAM full-word write/read",
        read_value,
        32'h1122_3344
    );

    // ----------------------------------------------------------
    // Partial byte write through the bus
    //
    // Initial word: 0x11223344
    // Replace byte lane 1 with 0xAA.
    // Expected: 0x1122AA44
    // ----------------------------------------------------------

    bus_write(
        DMEM_BASE,
        32'h0000_AA00,
        4'b0010
    );

    bus_read(DMEM_BASE, read_value);

    check_eq32(
        "RAM byte-enable forwarding",
        read_value,
        32'h1122_AA44
    );

    // ----------------------------------------------------------
    // Upper halfword merge
    //
    // Existing: 0x1122AA44
    // Write upper half: BEEF
    // Expected: 0xBEEFAA44
    // ----------------------------------------------------------

    bus_write(
        DMEM_BASE,
        32'hBEEF_0000,
        4'b1100
    );

    bus_read(DMEM_BASE, read_value);

    check_eq32(
        "RAM upper-halfword merge",
        read_value,
        32'hBEEF_AA44
    );

    // ----------------------------------------------------------
    // UART write
    // ----------------------------------------------------------

    cpu_addr       = UART_TX_ADDR;
    cpu_write_data = 32'h0000_0048;  // ASCII H
    cpu_byte_en    = 4'b0001;
    cpu_read_en    = 1'b0;
    cpu_write_en   = 1'b1;

    #1;

    check_eq1(
        "UART valid during write",
        uart_write_valid,
        1'b1
    );

    check_eq8(
        "UART data",
        uart_write_data,
        8'h48
    );

    @(posedge clk);
    #1;

    cpu_write_en = 1'b0;
    cpu_byte_en  = 4'b0000;

    #1;

    check_eq1(
        "UART valid after write",
        uart_write_valid,
        1'b0
    );

    // ----------------------------------------------------------
    // UART write must not modify RAM
    // ----------------------------------------------------------

    bus_read(DMEM_BASE, read_value);

    check_eq32(
        "UART write did not modify RAM",
        read_value,
        32'hBEEF_AA44
    );

    // ----------------------------------------------------------
    // UART read currently returns zero
    // ----------------------------------------------------------

    bus_read(UART_TX_ADDR, read_value);

    check_eq32(
        "UART read returns zero",
        read_value,
        32'h0000_0000
    );

    if (failures == 0) begin
      $display("PASS: all bus tests passed");
    end else begin
      $fatal(
          1,
          "FAIL: bus_tb had %0d failure(s)",
          failures
      );
    end

    $finish;
  end

endmodule
