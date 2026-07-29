module dmem #(
    parameter DEPTH = 256,
    parameter string INIT_FILE = ""
) (
    input logic clk,
    input logic mem_read_en,
    input logic mem_write_en,
    input logic [31:0] addr,
    input logic [31:0] write_data,
    
    output logic [31:0] read_data
);

    logic [31:0] mem [0:DEPTH-1];

    logic [31:0] local_addr;
    localparam logic [31:0] DMEM_BASE = 32'h0001_0000;

    localparam int WORDS = 256;
    logic addr_valid;

    assign local_addr = addr - DMEM_BASE;
    assign addr_valid = (addr >= DMEM_BASE) && (addr < DMEM_BASE + WORDS*4);

    initial begin
        if (INIT_FILE != "") $readmemh(INIT_FILE, mem);
    end

    always_ff @(posedge clk) begin
        if (mem_write_en && !addr_valid)
            $error("Invalid DMEM write: %08h", addr);

        if (mem_read_en && !addr_valid)
            $error("Invalid DMEM read: %08h", addr);

        if (mem_write_en && addr_valid)
            mem[local_addr[9:2]] <= write_data;
    end

    always_comb begin
        if (mem_read_en && addr_valid)
            read_data = mem[local_addr[9:2]];
        else
            read_data = 32'b0;
    end

endmodule
