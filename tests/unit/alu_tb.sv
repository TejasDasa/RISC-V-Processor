
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

    a = 32'hF0F0F0F0;
    b = 32'h0F0F0F0F;
    alu_op = ALU_AND;
    #1;

    if (result != 32'h00000000) begin
      $error("AND failed: expected 0, got %08h", result);
    end

    a = 32'hFFFF0000;
    b = 32'h0000FFFF;
    alu_op = ALU_OR;
    #1;

    if (result != 32'hFFFFFFFF) begin
      $error("OR failed: expected xFFFFFFFF, got %08h", result);
    end

    a = 32'hFF00FF00;
    b = 32'hFF000000;
    alu_op = ALU_XOR;
    #1;

    if (result != 32'h0000FF00) begin
      $error("XOR failed: expected x0000FF00, got %08h", result);
    end

    a = 32'd1;
    b = 32'd4;
    alu_op = ALU_SLL;
    #1;

    if (result != 32'd16) begin
      $error("SLL failed: expected 16, got %0d", result);
    end

    a = 32'h80000000;
    b = 32'd1;
    alu_op = ALU_SRL;
    #1;

    if (result != 32'h40000000) begin
      $error("SRL failed: expected x40000000, got %08h", result);
    end

    a = 32'h80000000;
    b = 32'd1;
    alu_op = ALU_SRA;
    #1;

    if (result != 32'hC0000000) begin
      $error("SRA failed: expected xC0000000, got %08h", result);
    end

    a = 32'hFFFFFFFF;
    b = 32'd1;
    alu_op = ALU_SLT;
    #1;

    if (result != 32'd1) begin
      $error("SLT failed: expected 1, got %0d", result);
    end

    a = 32'hFFFFFFFF;
    b = 32'd1;
    alu_op = ALU_SLTU;
    #1;

    if (result != 32'd0) begin
      $error("SLTU failed, expected 0, got %0d", result);
    end

    $display("PASS: all ALU tests passed");
    $finish;
  end

endmodule
