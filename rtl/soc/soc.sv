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
    output logic  uart_busy,

    output logic cpu_irq
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
    logic [31:0] timer_compare;
    logic [31:0] timer_control;

    logic timer_write_compare_en;
    logic timer_write_control_en;
    logic [31:0] timer_write_data;

    logic timer_irq;

    core #(
        .IMEM_INIT_FILE(IMEM_INIT_FILE)
    ) core_inst (
        .clk            (clk),
        .rst            (rst),

        .debug_pc       (debug_pc),
        .debug_instr    (debug_instr),

        .cpu_irq (cpu_irq),

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

        .cpu_read_data  (bus_read_data),

        .uart_write_valid  (uart_write_valid),
        .uart_write_data   (uart_write_data),
        .uart_busy (uart_busy),

        .timer_count (timer_count),
        .timer_compare (timer_compare),
        .timer_control (timer_control),

        .timer_write_compare_en (timer_write_compare_en),
        .timer_write_control_en (timer_write_control_en),
        .timer_write_data (timer_write_data)
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
        .write_compare_en (timer_write_compare_en),
        .write_control_en (timer_write_control_en),
        .write_data (timer_write_data),
        .counter (timer_count),
        .compare (timer_compare),
        .control (timer_control),
        .irq (timer_irq)
    );

    interrupt_controller interrupt_controller_inst (
        .timer_irq (timer_irq),
        .cpu_irq (cpu_irq)
    );

endmodule
