
module branch_unit_tb;

  import riscv_pkg::*;

  logic [31:0] rs1_data;
  logic [31:0] rs2_data;
  riscv_pkg::branch_op_t branch_op;

  logic taken;

  branch_unit dut (
      .rs1_data(rs1_data),
      .rs2_data(rs2_data),
      .branch_op(branch_op),
      .taken(taken)
  );

  int failures;

  task automatic check_eq32(input string test_name, input logic actual, input logic expected);
    if (actual !== expected) begin
      $error("%s failed: expected 0x%0d, got 0x%0d", test_name, expected, actual);
      failures++;
    end
  endtask

  initial begin
    rs1_data  = 32'd5;
    rs2_data  = 32'd5;
    branch_op = BR_EQ;
    #1;
    check_eq32("BR_EQ", taken, 1'b1);


    if (failures == 0) begin
      $display("PASS: all branch_unit tests passed");
    end else begin
      $fatal(1, "FAIL: branch_unit_tb had %0d failure(s)", failures);
    end

    $finish;
  end



endmodule
