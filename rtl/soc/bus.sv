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

    output logic uart_tx_valid,
    output logic [7:0]  uart_tx_data
);
    localparam logic [31:0] DMEM_BASE     = 32'h0001_0000;
    localparam logic [31:0] DMEM_END      = 32'h0001_0400;
    localparam logic [31:0] UART_TX_ADDR  = 32'h1000_0000;

    logic ram_selected;
    logic uart_selected;

    assign ram_selected = (cpu_addr >= DMEM_BASE) && (cpu_addr < DMEM_END);
    assign uart_selected = (cpu_addr == UART_TX_ADDR);

    logic ram_read_en;
    logic ram_write_en;

    assign ram_read_en = cpu_read_en && ram_selected;
    assign ram_write_en = cpu_write_en && ram_selected;

    assign uart_tx_valid = cpu_write_en && uart_selected;
    assign uart_tx_data = cpu_write_data[7:0];

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
        end else if (uart_selected) begin
            cpu_read_data = 32'b0;
        end
    end

    logic request_active;
    logic address_mapped;

    assign request_active = cpu_read_en || cpu_write_en;
    assign address_mapped = ram_selected || uart_selected;

    always_ff @(posedge clk) begin
        if (request_active && !address_mapped) begin
            $error(
                "Unmapped bus access: addr=%08h read=%0b write=%0b",
                cpu_addr, cpu_read_en, cpu_write_en);
        end
    end


endmodule
