module dmem_tb;

  localparam int DEPTH = 256;
  localparam logic [31:0] DMEM_BASE = 32'h0001_0000;

  logic clk;
  logic mem_read_en;
  logic mem_write_en;
  logic [31:0] addr;
  logic [31:0] write_data;
  logic [3:0] byte_en;
  logic [31:0] read_data;

  int failures;

  dmem #(
      .DEPTH(DEPTH),
      .INIT_FILE("")
  ) dut (
      .clk          (clk),
      .mem_read_en  (mem_read_en),
      .mem_write_en (mem_write_en),
      .addr         (addr),
      .write_data   (write_data),
      .byte_en      (byte_en),
      .read_data    (read_data)
  );

  task automatic check_eq32(
      input string test_name,
      input logic [31:0] actual,
      input logic [31:0] expected
  );
    if (actual !== expected) begin
      $error("%s failed: expected 0x%08h, got 0x%08h",
             test_name, expected, actual);
      failures++;
    end
  endtask

  task automatic write_word(
      input logic [31:0] address,
      input logic [31:0] value,
      input logic [3:0] enables
  );
    mem_read_en  = 1'b0;
    mem_write_en = 1'b1;
    addr         = address;
    write_data   = value;
    byte_en      = enables;

    @(posedge clk);
    #1;

    mem_write_en = 1'b0;
    byte_en      = 4'b0000;
  endtask

  task automatic check_read(
      input string test_name,
      input logic [31:0] address,
      input logic [31:0] expected
  );
    mem_write_en = 1'b0;
    mem_read_en  = 1'b1;
    addr         = address;
    #1;

    check_eq32(test_name, read_data, expected);

    mem_read_en = 1'b0;
  endtask

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    failures    = 0;
    mem_read_en = 1'b0;
    mem_write_en = 1'b0;
    addr        = DMEM_BASE;
    write_data  = 32'b0;
    byte_en     = 4'b0000;

    // Full word at DMEM base maps to mem[0].
    write_word(DMEM_BASE, 32'hDEAD_BEEF, 4'b1111);
    check_read("full-word base write/read",
               DMEM_BASE, 32'hDEAD_BEEF);
    check_eq32("base maps to mem[0]",
               dut.mem[0], 32'hDEAD_BEEF);

    // Next word maps to mem[1].
    write_word(DMEM_BASE + 32'd4, 32'h1234_5678, 4'b1111);
    check_read("full-word next address",
               DMEM_BASE + 32'd4, 32'h1234_5678);
    check_eq32("base+4 maps to mem[1]",
               dut.mem[1], 32'h1234_5678);

    // Disabled write must not alter memory.
    mem_write_en = 1'b0;
    addr         = DMEM_BASE + 32'd4;
    write_data   = 32'hFFFF_FFFF;
    byte_en      = 4'b1111;
    @(posedge clk);
    #1;
    check_read("disabled write preserves word",
               DMEM_BASE + 32'd4, 32'h1234_5678);

    // Read disabled returns zero.
    mem_read_en = 1'b0;
    addr        = DMEM_BASE;
    #1;
    check_eq32("read disabled", read_data, 32'h0000_0000);

    // Byte-lane writes merge with existing word.
    write_word(DMEM_BASE + 32'd8, 32'h1122_3344, 4'b1111);

    write_word(DMEM_BASE + 32'd8, 32'h0000_00AA, 4'b0001);
    check_read("byte lane 0",
               DMEM_BASE + 32'd8, 32'h1122_33AA);

    write_word(DMEM_BASE + 32'd8, 32'h0000_BB00, 4'b0010);
    check_read("byte lane 1",
               DMEM_BASE + 32'd8, 32'h1122_BBAA);

    write_word(DMEM_BASE + 32'd8, 32'h00CC_0000, 4'b0100);
    check_read("byte lane 2",
               DMEM_BASE + 32'd8, 32'h11CC_BBAA);

    write_word(DMEM_BASE + 32'd8, 32'hDD00_0000, 4'b1000);
    check_read("byte lane 3",
               DMEM_BASE + 32'd8, 32'hDDCC_BBAA);

    // Lower-halfword merge.
    write_word(DMEM_BASE + 32'd12, 32'h1122_3344, 4'b1111);
    write_word(DMEM_BASE + 32'd12, 32'h0000_BEEF, 4'b0011);
    check_read("lower halfword merge",
               DMEM_BASE + 32'd12, 32'h1122_BEEF);

    // Upper-halfword merge: regression for the duplicate whole-word write bug.
    write_word(DMEM_BASE + 32'd12, 32'hCAFE_0000, 4'b1100);
    check_read("upper halfword merge",
               DMEM_BASE + 32'd12, 32'hCAFE_BEEF);

    // An unaligned address still selects the containing 32-bit RAM word.
    // Misalignment policy/trapping belongs above this raw memory module.
    check_read("unaligned address selects same word",
               DMEM_BASE + 32'd13, 32'hCAFE_BEEF);

    // Highest valid word.
    write_word(DMEM_BASE + (DEPTH * 4) - 4,
               32'hA5A5_5A5A, 4'b1111);
    check_read("last valid word",
               DMEM_BASE + (DEPTH * 4) - 4,
               32'hA5A5_5A5A);

    if (failures == 0) begin
      $display("PASS: all dmem tests passed");
    end else begin
      $fatal(1, "FAIL: dmem_tb had %0d failure(s)", failures);
    end

    $finish;
  end

endmodule
