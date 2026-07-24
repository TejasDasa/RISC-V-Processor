
module imem #(
    parameter DEPTH = 256,
    parameter INIT_FILE = ""
) (
    input  logic [31:0] addr,
    output logic [31:0] instr
);

  logic [31:0] mem [0:DEPTH-1];

  initial begin
    if (INIT_FILE != "") begin
      $readmemh(INIT_FILE, mem);
    end
  end

  assign instr = mem[addr[9:2]];

endmodule
