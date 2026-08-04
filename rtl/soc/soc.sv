module soc #(
    parameter string IMEM_INIT_FILE = "",
    parameter string DMEM_INIT_FILE = ""
) (
    input  logic        clk,
    input  logic        rst,

    output logic [31:0] debug_pc,
    output logic [31:0] debug_instr,

    output logic        uart_tx_valid,
    output logic [7:0]  uart_tx_data
);

    logic [31:0] bus_addr;
    logic        bus_read_en;
    logic        bus_write_en;
    logic [31:0] bus_write_data;
    logic [3:0]  bus_byte_en;
    logic [31:0] bus_read_data;

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

        .cpu_read_data  (bus_read_data),

        .uart_tx_valid  (uart_tx_valid),
        .uart_tx_data   (uart_tx_data)
    );

endmodule
