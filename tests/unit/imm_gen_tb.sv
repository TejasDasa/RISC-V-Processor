
module imm_gen_tb;

  import riscv_pkg::*;

  logic [31:0] instr;
  riscv_pkg::imm_type_t imm_type;

  logic [31:0] imm;

  imm_gen dut (
      .instr(instr),
      .imm_type(imm_type),
      .imm(imm)
  );

  int failures;

  task automatic check_eq32(input string test_name, input logic [31:0] actual,
                            input logic [31:0] expected);
    if (actual !== expected) begin
      $error("%s failed: expected 0x%08h, got 0x%08h", test_name, expected, actual);
      failures++;
    end
  endtask

  initial begin

    // Type I tests
    instr = 32'b0;
    instr[31:20] = 12'd5;
    imm_type = IMM_I;
    #1;
    check_eq32("IMM_I positive", imm, 32'd5);

    instr = 32'b0;
    instr[31:20] = 12'hFFF;
    imm_type = IMM_I;
    #1;
    check_eq32("IMM_I negative", imm, 32'hFFFFFFFF);

    instr = 32'b0;
    instr[31:20] = 12'h800;
    imm_type = IMM_I;
    #1;
    check_eq32("IMM_I large", imm, 32'hFFFF_F800);


    // Type B tests
    instr = 32'b0;
    instr[11:8] = 4'b0100;
    imm_type = IMM_B;
    #1;
    check_eq32("IMM_B positive", imm, 32'd8);

    instr = 32'b0;
    instr[31] = 1'b1;
    instr[7] = 1'b1;
    instr[30:25] = 6'b111111;
    instr[11:8] = 4'b1110;
    imm_type = IMM_B;
    #1;
    check_eq32("IMM_B negative", imm, 32'hFFFFFFFC);

    instr = 32'b0;
    instr[31] = 1'b1;
    instr[7] = 1'b0;
    instr[30:25] = 6'b000000;
    instr[11:8] = 4'b0000;
    imm_type = IMM_B;
    #1;
    check_eq32("IMM_B negative large", imm, 32'hFFFFF000);


    // Type U tests
    instr = 32'b0;
    instr[31:12] = 20'hABCDE;
    imm_type = IMM_U;
    #1;
    check_eq32("IMM_U upper", imm, 32'hABCDE000);

    instr = 32'b0;
    instr[31:12] = 20'h00001;
    imm_type = IMM_U;
    #1;
    check_eq32("IMM_U lower", imm, 32'h00001000);

    instr = 32'b0;
    instr[31:12] = 20'hFFFFF;
    imm_type = IMM_U;
    #1;
    check_eq32("IMM_U large", imm, 32'hFFFFF000);


    // Type S tests
    instr = 32'b0;
    instr[31:25] = 7'b0000001;
    instr[11:7] = 5'b00000;
    imm_type = IMM_S;
    #1;
    check_eq32("IMM_S positive", imm, 32'd32);

    instr = 32'b0;
    instr[31:25] = 7'b1111111;
    instr[11:7] = 5'b11111;
    imm_type = IMM_S;
    #1;
    check_eq32("IMM_S negative", imm, 32'hFFFFFFFF);


    // Type J tests
    instr = 32'b0;
    instr[30:21] = 10'b0000001000;
    imm_type = IMM_J;
    #1;
    check_eq32("IMM_J positive", imm, 32'd16);

    instr = 32'b0;
    instr[31] = 1'b1;
    imm_type = IMM_J;
    #1;
    check_eq32("IMM_J negative", imm, 32'hFFF00000);


    if (failures == 0) begin
      $display("PASS: all imm_gen tests passed");
    end else begin
      $fatal(1, "FAIL: imm_gen_tb had %0d failure(s)", failures);
    end

    $finish;
  end

endmodule
