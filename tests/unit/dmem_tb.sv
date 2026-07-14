module dmem_tb;

  logic clk;
  logic mem_read_en;
  logic mem_write_en;
  logic [31:0] addr;
  logic [31:0] write_data;
  logic [31:0] read_data;

  dmem dut (
      .clk(clk),
      .mem_read_en(mem_read_en),
      .mem_write_en(mem_write_en),
      .addr(addr),
      .write_data(write_data),
      .read_data(read_data)
  );

  int failures;

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

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    failures = 0;

    mem_read_en  = 1'b0;
    mem_write_en = 1'b0;
    addr         = 32'b0;
    write_data   = 32'b0;

    // Write 0xDEADBEEF to address 0
    addr         = 32'd0;
    write_data   = 32'hDEAD_BEEF;
    mem_write_en = 1'b1;
    @(posedge clk);
    #1;
    mem_write_en = 1'b0;

    // Read address 0
    mem_read_en = 1'b1;
    addr        = 32'd0;
    #1;
    check_eq32("dmem read addr 0", read_data, 32'hDEAD_BEEF);

    // Write 0x12345678 to address 4
    mem_read_en  = 1'b0;
    addr         = 32'd4;
    write_data   = 32'h1234_5678;
    mem_write_en = 1'b1;
    @(posedge clk);
    #1;
    mem_write_en = 1'b0;

    // Read address 4
    mem_read_en = 1'b1;
    addr        = 32'd4;
    #1;
    check_eq32("dmem read addr 4", read_data, 32'h1234_5678);

    // mem_write_en = 0 should not overwrite address 4
    mem_read_en  = 1'b0;
    addr         = 32'd4;
    write_data   = 32'hFFFF_FFFF;
    mem_write_en = 1'b0;
    @(posedge clk);
    #1;

    mem_read_en = 1'b1;
    addr        = 32'd4;
    #1;
    check_eq32("dmem no-write hold addr 4", read_data, 32'h1234_5678);

    // mem_read_en = 0 should output 0
    mem_read_en = 1'b0;
    addr        = 32'd4;
    #1;
    check_eq32("dmem read disabled", read_data, 32'h0000_0000);

    // Address 8 maps to mem[2]
    mem_read_en  = 1'b0;
    addr         = 32'd8;
    write_data   = 32'hCAFE_BABE;
    mem_write_en = 1'b1;
    @(posedge clk);
    #1;
    mem_write_en = 1'b0;

    mem_read_en = 1'b1;
    addr        = 32'd8;
    #1;
    check_eq32("dmem read addr 8", read_data, 32'hCAFE_BABE);

    // Unaligned address 9 still maps to addr[9:2] = 2 for now
    addr = 32'd9;
    #1;
    check_eq32("dmem unaligned addr 9", read_data, 32'hCAFE_BABE);

    if (failures == 0) begin
      $display("PASS: all dmem tests passed");
    end else begin
      $fatal(1, "FAIL: dmem_tb had %0d failure(s)", failures);
    end

    $finish;
  end

endmodule
