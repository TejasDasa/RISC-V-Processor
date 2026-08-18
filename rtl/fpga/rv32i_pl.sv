module rv32i_pl (
    input  logic       clk,
    input  logic       rst,

    input  logic       uart_ack,
    output logic [8:0] uart_mailbox,

    output logic       led_run,
    output logic       led_pc
);

    logic [31:0] debug_pc;
    logic [31:0] debug_instr;

    logic cpu_irq;

    logic       soc_uart_valid;
    logic [7:0] soc_uart_data;
    logic       soc_uart_busy;

    logic [31:0] gpio_out;

    soc #(
        .IMEM_INIT_FILE("/home/tejas-dasa/Projects/RISC-V-Processor/software/build/fpga_test_imem.hex"),
        .DMEM_INIT_FILE("/home/tejas-dasa/Projects/RISC-V-Processor/software/build/fpga_test_dmem.hex"),
        .UART_CLOCK_HZ(12_500_000),
        .UART_BAUD_RATE(115200)
    ) soc_inst (
        .clk (clk),
        .rst (rst),

        .debug_pc    (debug_pc),
        .debug_instr (debug_instr),

        .uart_write_valid   (soc_uart_valid),
        .uart_write_data    (soc_uart_data),
        .uart_external_busy (soc_uart_busy),

        .cpu_irq  (cpu_irq),
        .gpio_out (gpio_out)
    );

    assign led_run = !rst;
    assign led_pc = gpio_out[0];


    // ------------------------------------------------------------
    // ACK CDC synchronizer
    // ------------------------------------------------------------

    logic uart_ack_sync1;
    logic uart_ack_sync2;

    always_ff @(posedge clk) begin
        if (rst) begin
            uart_ack_sync1 <= 1'b0;
            uart_ack_sync2 <= 1'b0;
        end else begin
            uart_ack_sync1 <= uart_ack;
            uart_ack_sync2 <= uart_ack_sync1;
        end
    end

    // ------------------------------------------------------------
    // UART mailbox
    // ------------------------------------------------------------

    typedef enum logic [1:0] {
        MB_IDLE,
        MB_VALID,
        MB_WAIT_ACK_LOW
    } mailbox_state_t;

    mailbox_state_t mailbox_state;

    logic [7:0] mailbox_data;

    always_ff @(posedge clk) begin
        if (rst) begin
            mailbox_state <= MB_IDLE;
            mailbox_data  <= 8'b0;
        end else begin

            unique case (mailbox_state)

                MB_IDLE: begin
                    if (soc_uart_valid) begin
                        mailbox_data  <= soc_uart_data;
                        mailbox_state <= MB_VALID;
                    end
                end

                MB_VALID: begin
                    if (uart_ack_sync2) begin
                        mailbox_state <= MB_WAIT_ACK_LOW;
                    end
                end

                MB_WAIT_ACK_LOW: begin
                    if (!uart_ack_sync2) begin
                        mailbox_state <= MB_IDLE;
                    end
                end

                default: begin
                    mailbox_state <= MB_IDLE;
                end

            endcase
        end
    end

    assign uart_mailbox[7:0] = mailbox_data;

    assign uart_mailbox[8] =
        (mailbox_state == MB_VALID);

    assign soc_uart_busy =
        (mailbox_state != MB_IDLE);

endmodule