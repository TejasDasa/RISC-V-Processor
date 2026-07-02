
module regfile_tb;

  logic        clk;
  logic        we;

  logic [ 4:0] rs1_addr;
  logic [ 4:0] rs2_addr;
  logic [ 4:0] rd_addr;

  logic [31:0] rd_data;

  logic [31:0] rs1_data;
  logic [31:0] rs2_data;

  regfile dut (
      .clk(clk),
      .we(we),
      .rs1_addr(rs1_addr),
      .rs2_addr(rs2_addr),
      .rd_addr(rd_addr),
      .rd_data(rd_data),
      .rs1_data(rs1_data),
      .rs2_data(rs2_data)
  );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  int failures;

  task automatic check_eq32(input string test_name, input logic [31:0] actual,
                            input logic [31:0] expected);
    if (actual !== expected) begin
      $error("%s failed: expected 0x%08h, got 0x%08h", test_name, expected, actual);
      failures++;
    end
  endtask

  initial begin
    we = 1'b0;
    rs1_addr = 5'd0;
    rs2_addr = 5'd0;
    rd_addr = 5'd0;
    rd_data = 32'd0;

    #1;

    check_eq32("x0 rs1 read", rs1_data, 32'd0);

    check_eq32("x0 rs2 read", rs2_data, 32'd0);

    we = 1'b1;
    rd_addr = 5'd1;
    rd_data = 32'd123;

    @(posedge clk);
    #1;

    //The write happens at the next rising edge of clk.

    we = 1'b0;
    rs1_addr = 5'd1;
    #1;

    check_eq32("x1 write/read", rs1_data, 32'd123);

    we = 1'b1;
    rd_addr = 5'd2;
    rd_data = 32'd456;

    @(posedge clk);
    #1;

    we = 1'b0;
    rs2_addr = 5'd2;
    #1;

    check_eq32("x2 write/read", rs2_data, 32'd456);

    rs1_addr = 5'd1;
    rs2_addr = 5'd2;
    #1;

    if ((rs1_data != 32'd123) && (rs2_data != 32'd456))
      $error("x1 and x2 read failed: expected 123 and 456, got %0d and %0d", rs1_data, rs2_data);

    we = 1'b1;
    rd_addr = 5'd0;
    rd_data = 32'd999;

    @(posedge clk);
    #1;

    we = 1'b0;
    rs1_addr = 5'd0;
    #1;

    check_eq32("x0 write-ignore", rs1_data, 32'd0);

    // First write known value to x3
    we = 1'b1;
    rd_addr = 5'd3;
    rd_data = 32'd111;

    @(posedge clk);
    #1;

    // Now attempt overwrite with write disabled
    we = 1'b0;
    rd_addr = 5'd3;
    rd_data = 32'd777;

    @(posedge clk);
    #1;

    rs1_addr = 5'd3;
    #1;

    check_eq32("write-enable", rs1_data, 32'd111);

    if (failures == 0) begin
      $display("PASS: all regfile tests passed");
    end else begin
      $fatal(1, "FAIL: regfile_tb had %0d failure(s)", failures);
    end

    $finish;

  end
endmodule
