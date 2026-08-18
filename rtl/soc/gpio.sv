module gpio (
    input  logic        clk,
    input  logic        rst,

    input  logic        write_en,
    input  logic [31:0] write_data,

    output logic [31:0] value
);

    always_ff @(posedge clk) begin
        if (rst) begin
            value <= 32'b0;
        end else if (write_en) begin
            value <= write_data;
        end
    end

endmodule
