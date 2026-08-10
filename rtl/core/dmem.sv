module dmem #(
    parameter DEPTH = 2048,
    parameter string INIT_FILE = ""
) (
    input  logic        clk,
    input  logic        mem_read_en,
    input  logic        mem_write_en,
    input  logic [31:0] addr,
    input  logic [31:0] write_data,
    input  logic [3:0]  byte_en,

    output logic [31:0] read_data
);

    logic [31:0] mem [0:DEPTH-1];

    localparam logic [31:0] DMEM_BASE = 32'h0001_0000;
    localparam int ADDR_WIDTH = $clog2(DEPTH);

    logic [31:0] local_addr;
    logic        addr_valid;

    assign local_addr = addr - DMEM_BASE;

    assign addr_valid =
        (addr >= DMEM_BASE) &&
        (addr < DMEM_BASE + DEPTH * 4);

    initial begin
        if (INIT_FILE != "")
            $readmemh(INIT_FILE, mem);
    end

    always_comb begin
        if (mem_read_en && addr_valid)
            read_data = mem[local_addr[ADDR_WIDTH+1:2]];
        else
            read_data = 32'b0;
    end

    always_ff @(posedge clk) begin
        if (mem_read_en && !addr_valid) begin
            $error(
                "Invalid DMEM read: %08h",
                addr
            );
        end

        if (mem_write_en && !addr_valid) begin
            $error(
                "Invalid DMEM write: %08h",
                addr
            );
        end

        if (mem_write_en && addr_valid) begin
            if (byte_en[0])
                mem[local_addr[ADDR_WIDTH+1:2]][7:0]
                    <= write_data[7:0];

            if (byte_en[1])
                mem[local_addr[ADDR_WIDTH+1:2]][15:8]
                    <= write_data[15:8];

            if (byte_en[2])
                mem[local_addr[ADDR_WIDTH+1:2]][23:16]
                    <= write_data[23:16];

            if (byte_en[3])
                mem[local_addr[ADDR_WIDTH+1:2]][31:24]
                    <= write_data[31:24];
        end
    end

endmodule