interface cpu_if(input logic clk);

    logic rst;

    logic [31:0] debug_pc;
    logic [31:0] debug_instr;

    logic [31:0] bus_addr;
    logic        bus_read_en;
    logic        bus_write_en;
    logic [31:0] bus_write_data;
    logic [3:0]  bus_byte_en;
    logic [31:0] bus_read_data;

endinterface
