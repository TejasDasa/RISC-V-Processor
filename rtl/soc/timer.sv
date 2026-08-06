module timer(
    input logic clk,
    input logic rst,

    output logic [31:0] counter
);

always_ff @(posedge clk) begin
    if (rst) begin
        counter <= 32'b0;
    end else begin
        counter <= counter + 32'd1;
    end
end

endmodule
