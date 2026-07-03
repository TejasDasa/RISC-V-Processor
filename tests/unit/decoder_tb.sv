
module decoder_tb ();

  import riscv_pkg::*;

  logic [31:0] instr;

  logic [4:0] rd_addr;
  logic [4:0] rs1_addr;
  logic [4:0] rs2_addr;

  riscv_pkg::alu_op_t alu_op;
  riscv_pkg::imm_type_t imm_type;

  logic reg_write_en;
  logic alu_src_imm;
  logic illegal_instr;

  decoder dut (
      .instr(instr),
      .rd_addr(rd_addr),
      .rs1_addr(rs1_addr),
      .rs2_addr(rs2_addr),
      .alu_op(alu_op),
      .imm_type(imm_type),
      .reg_write_en(reg_write_en),
      .alu_src_imm(alu_src_imm),
      .illegal_instr(illegal_instr)
  );

  int failures;

  task automatic check_eq5(input string test_name, input logic [4:0] actual,
                           input logic [4:0] expected);
    if (actual !== expected) begin
      $error("%s failed: expected 0x%0d, got 0x%0d", test_name, expected, actual);
      failures++;
    end
  endtask

  task automatic check_eq1(input string test_name, input logic actual, input logic expected);
    if (actual !== expected) begin
      $error("%s failed: expected 0b%0b, got 0b%0b", test_name, expected, actual);
      failures++;
    end
  endtask

  initial begin

    failures = 0;

    instr = 32'd0;
    instr[6:0] = OPCODE_LUI;
    instr[11:7] = 5'd5;
    instr[31:12] = 20'h12345;
    #1;

    check_eq5("LUI rd addr", rd_addr, 5'd5);
    check_eq1("LUI reg write en", reg_write_en, 1'b1);
    check_eq1("LUI alu src imm", alu_src_imm, 1'b1);
    check_eq1("LUI illegal instr", illegal_instr, 1'b0);

    if (imm_type != IMM_U) $error("Imm type incorrect");
    if (alu_op != ALU_ADD) $error("ALU op incorrect");



    if (failures == 0) begin
      $display("PASS: all decoder tests passed");
    end else begin
      $fatal(1, "FAIL: decoder_tb had %0d failure(s)", failures);
    end

    $finish;
  end

endmodule
