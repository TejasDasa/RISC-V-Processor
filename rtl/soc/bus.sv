module bus #(
    parameter string DMEM_INIT_FILE = ""
) (
    input  logic clk,
    input  logic rst,

    input  logic [31:0] cpu_addr,
    input  logic cpu_read_en,
    input  logic cpu_write_en,
    input  logic [31:0] cpu_write_data,
    input  logic [3:0]  cpu_byte_en,

    output logic [31:0] cpu_read_data,

    output logic uart_write_valid,
    output logic [7:0]  uart_write_data,
    input logic uart_busy
);
    import soc_pkg::*;

    logic ram_selected;
    logic uart_data_selected;
    logic uart_status_selected;

    assign ram_selected = (cpu_addr >= DMEM_BASE) && (cpu_addr < DMEM_END);
    assign uart_data_selected   = (cpu_addr == UART_TX_ADDR);
    assign uart_status_selected = (cpu_addr == UART_TX_STATUS);

    logic ram_read_en;
    logic ram_write_en;

    assign ram_read_en = cpu_read_en && ram_selected;
    assign ram_write_en = cpu_write_en && ram_selected;

    assign uart_write_valid = (cpu_write_en && uart_data_selected && !uart_busy);
    assign uart_write_data = cpu_write_data[7:0];

    logic [31:0] ram_read_data;

    dmem #(
        .INIT_FILE(DMEM_INIT_FILE)
    ) dmem_inst (
        .clk(clk),
        .mem_read_en(ram_read_en),
        .mem_write_en(ram_write_en),
        .byte_en(cpu_byte_en),
        .addr(cpu_addr),
        .write_data(cpu_write_data),
        .read_data(ram_read_data)
    );

    always_comb begin
        cpu_read_data = 32'b0;

        if (ram_selected) begin
            cpu_read_data = ram_read_data;
        end else if (uart_status_selected) begin
            cpu_read_data = {31'b0, uart_busy};
        end
    end

    logic request_active;
    logic address_mapped;

    assign request_active = cpu_read_en || cpu_write_en;
    assign address_mapped = ram_selected || uart_data_selected || uart_status_selected;

    always_ff @(posedge clk) begin
        if (request_active && !address_mapped) begin
            $error(
                "Unmapped bus access: addr=%08h read=%0b write=%0b",
                cpu_addr, cpu_read_en, cpu_write_en);
        end

        if (cpu_write_en && uart_data_selected && uart_busy) begin
            $error(
                "UART write attempted while transmitter busy: data=%02h",
                cpu_write_data[7:0]
            );
        end

        if (cpu_write_en && uart_status_selected) begin
            $error("Write attempted to read-only UART status register");
        end
    end
endmodule
