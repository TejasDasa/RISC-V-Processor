module timer(
    input logic clk,
    input logic rst,

    input logic write_compare_en,
    input logic write_control_en,
    input logic [31:0] write_data,

    output logic [31:0] counter,
    output logic [31:0] compare,
    output logic [31:0] control,

    output logic irq
);

logic enable;
logic interrupt_enable;

assign enable = control[0];
assign interrupt_enable = control[1];

assign irq = enable && interrupt_enable && (counter >= compare);

always_ff @(posedge clk) begin
    if (rst) begin
        counter <= 32'b0;
        compare <= 32'b0;
        control <= 32'b0;
    end else begin
        if (write_compare_en) compare <= write_data;
        if (write_control_en) control <= write_data;
        if (enable) counter <= counter + 32'd1;
    end
end

endmodule
