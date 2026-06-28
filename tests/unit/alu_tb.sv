
module alu_tb;

    import riscv_pkg::*;

    logic [31:0] a;
    logic [31:0] b;
    riscv_pkg::alu_op_t alu_op;
    logic [31:0] result;

    alu dut (
        .a(a),
        .b(b),
        .alu_op(alu_op),
        .result(result)
    );

    initial begin
    a = 32'd5;
    b = 32'd7;
    alu_op = ALU_ADD;
    #1;

    if (result != 32'd12) begin
      $error("ADD failed: expected 12, got %0d", result);
    end

    a = 32'd7;
    b = 32'd5;
    alu_op = ALU_SUB;
    #1;

    if (result != 32'd2) begin
      $error("SUB failed: expected 2, got %0d", result);
    end

    $display("ALU basic tests finished");
    $finish;
  end

endmodule
