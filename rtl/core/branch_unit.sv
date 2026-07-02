
module branch_unit (
    input logic [31:0] rs1_data,
    input logic [31:0] rs2_data,
    input riscv_pkg::branch_op_t branch_op,

    output logic taken
);

  import riscv_pkg::*;

  always_comb begin
    taken = 1'b0;

    unique case (branch_op)

      BR_NONE: taken = 1'b0;

      BR_EQ: if (rs1_data == rs2_data) taken = 1'b1;

      BR_NE: if (rs1_data != rs2_data) taken = 1'b1;

      BR_LT: if ($signed(rs1_data) < $signed(rs2_data)) taken = 1'b1;

      BR_GE: if ($signed(rs1_data) >= $signed(rs2_data)) taken = 1'b1;

      BR_LTU: if (rs1_data < rs2_data) taken = 1'b1;

      BR_GEU: if (rs1_data >= rs2_data) taken = 1'b1;

      default: taken = 1'b0;

    endcase
  end

endmodule
