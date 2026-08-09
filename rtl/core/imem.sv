
module imem #(
    parameter DEPTH = 1024,
    parameter string INIT_FILE = ""
) (
    input  logic [31:0] addr,
    output logic [31:0] instr
);

  logic [31:0] mem [0:DEPTH-1];

  localparam ADDR_WIDTH = $clog2(DEPTH);

  assign instr = mem[addr[ADDR_WIDTH+1:2]];

  initial begin
    if (INIT_FILE != "") begin
      $readmemh(INIT_FILE, mem);
    end
  end

endmodule
