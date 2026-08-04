module uart_tx #(
    parameter CLOCK_HZ = 10,
    parameter BAUD_RATE = 2
) (
    input logic clk,
    input logic rst,
    input logic valid,
    input logic [7:0] data,

    output logic tx,
    output logic busy
);

localparam int CLKS_PER_BIT = CLOCK_HZ / BAUD_RATE;

localparam int BAUD_COUNTER_WIDTH = (CLKS_PER_BIT <= 1) ? 1 : $clog2(CLKS_PER_BIT);

logic [BAUD_COUNTER_WIDTH-1:0] baud_counter;

logic [2:0] bit_index;

logic [7:0] data_reg;

typedef enum logic [1:0] {
    IDLE,
    START,
    DATA,
    STOP
} uart_state;

uart_state state;

always_ff @(posedge clk) begin
    if (rst == 1'b1) begin
        state <= IDLE;
        baud_counter <= '0;
        bit_index <= 3'b0;
        data_reg <= 8'b0;
    end

    unique case (state)
        IDLE: begin
            baud_counter <= '0;
            bit_index <= 3'b0;
            
            if (valid) begin
                data_reg <= data;
                state <= START;
            end
        end

        START: begin
            if (baud_counter == CLKS_PER_BIT - 1) begin
                baud_counter <= '0;
                state <= DATA;
            end else begin
                baud_counter <= baud_counter + 1'b1;
            end
        end

        DATA: begin
            if (baud_counter == CLKS_PER_BIT - 1) begin
                baud_counter <= '0;

                if (bit_index == 3'd7) begin
                    bit_index <= '0;
                    state     <= STOP;
                end else begin
                    bit_index <= bit_index + 1'b1;
                end

            end else baud_counter <= baud_counter + 1'b1;
        end

        STOP: begin
            if (baud_counter == CLKS_PER_BIT - 1) begin
                baud_counter <= '0;
                state        <= IDLE;
            end else begin
                baud_counter <= baud_counter + 1'b1;
            end
        end

        default: begin
            state        <= IDLE;
            baud_counter <= '0;
            bit_index    <= '0;
        end
    endcase
end

always_comb begin
    tx   = 1'b1;
    busy = 1'b1;

    unique case (state)
        IDLE: begin
            tx   = 1'b1;
            busy = 1'b0;
        end

        START: tx = 1'b0;

        DATA: tx = data_reg[bit_index];

        STOP: tx = 1'b1;

        default: begin
            tx   = 1'b1;
            busy = 1'b0;
        end
    endcase
end

endmodule
