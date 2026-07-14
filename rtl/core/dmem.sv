module dmem #(
    parameter DEPTH = 256
) (
    input logic clk,
    input logic mem_read_en,
    input logic mem_write_en,
    input logic [31:0] addr,
    input logic [31:0] write_data,
    
    output logic [31:0] read_data
);

    logic [31:0] mem [0:DEPTH-1];

    always_ff @(posedge clk) begin
        if (mem_write_en) begin
            mem[addr[9:2]] <= write_data;
        end
    end

    always_comb begin
        if (mem_read_en) begin
            read_data = mem[addr[9:2]];
        end else begin
            read_data = 0;
        end
    end

endmodule
