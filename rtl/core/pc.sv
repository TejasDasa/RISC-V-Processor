module pc (
    input logic clk,
    input logic rst,
    input logic pc_we,
    input logic [31:0] next_pc,

    output logic [31:0] pc
);

    always_ff @(posedge clk) begin
        if (rst) begin
            pc <= 32'd0;
        end else if (pc_we) begin
            pc <= next_pc;
        end
        
    end

endmodule
