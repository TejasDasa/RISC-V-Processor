module soc #(
    parameter string IMEM_INIT_FILE = "",
    parameter string DMEM_INIT_FILE = "",
    parameter int UART_CLOCK_HZ = 10,
    parameter int UART_BAUD_RATE = 2
) (
    input  logic        clk,
    input  logic        rst,

    output logic [31:0] debug_pc,
    output logic [31:0] debug_instr,

    output logic  uart_tx,
    output logic  uart_busy
);

    logic [31:0] bus_addr;
    logic        bus_read_en;
    logic        bus_write_en;
    logic [31:0] bus_write_data;
    logic [3:0]  bus_byte_en;
    logic [31:0] bus_read_data;
    
    logic uart_write_valid;
    logic [7:0] uart_write_data;

    logic [31:0] timer_count;

    core #(
        .IMEM_INIT_FILE(IMEM_INIT_FILE)
    ) core_inst (
        .clk            (clk),
        .rst            (rst),

        .debug_pc       (debug_pc),
        .debug_instr    (debug_instr),

        .bus_addr       (bus_addr),
        .bus_read_en    (bus_read_en),
        .bus_write_en   (bus_write_en),
        .bus_write_data (bus_write_data),
        .bus_byte_en    (bus_byte_en),
        .bus_read_data  (bus_read_data)
    );

    bus #(
        .DMEM_INIT_FILE(DMEM_INIT_FILE)
    ) bus_inst (
        .clk            (clk),
        .rst            (rst),

        .cpu_addr       (bus_addr),
        .cpu_read_en    (bus_read_en),
        .cpu_write_en   (bus_write_en),
        .cpu_write_data (bus_write_data),
        .cpu_byte_en    (bus_byte_en),

        .timer_count (timer_count),

        .cpu_read_data  (bus_read_data),

        .uart_write_valid  (uart_write_valid),
        .uart_write_data   (uart_write_data),
        .uart_busy (uart_busy)
    );

    uart_tx #(
        .CLOCK_HZ  (UART_CLOCK_HZ),
        .BAUD_RATE (UART_BAUD_RATE)
    ) uart_tx_inst (
        .clk   (clk),
        .rst   (rst),
        .valid (uart_write_valid),
        .data  (uart_write_data),
        .tx    (uart_tx),
        .busy  (uart_busy)
    );

    timer timer_inst (
        .clk (clk),
        .rst (rst),
        .counter (timer_count)
    );

endmodule
