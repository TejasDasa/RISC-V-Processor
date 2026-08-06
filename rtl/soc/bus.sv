module bus #(
    parameter string DMEM_INIT_FILE = ""
) (
    input  logic        clk,
    input  logic        rst,

    // CPU bus interface
    input  logic [31:0] cpu_addr,
    input  logic        cpu_read_en,
    input  logic        cpu_write_en,
    input  logic [31:0] cpu_write_data,
    input  logic [3:0]  cpu_byte_en,

    output logic [31:0] cpu_read_data,

    // UART interface
    output logic        uart_write_valid,
    output logic [7:0]  uart_write_data,
    input  logic        uart_busy,

    // Timer register inputs
    input  logic [31:0] timer_count,
    input  logic [31:0] timer_compare,
    input  logic [31:0] timer_control,

    // Timer write interface
    output logic        timer_write_compare_en,
    output logic        timer_write_control_en,
    output logic [31:0] timer_write_data
);

  import soc_pkg::*;


  // Address decode

  logic ram_selected;

  logic uart_data_selected;
  logic uart_status_selected;

  logic timer_count_selected;
  logic timer_compare_selected;
  logic timer_control_selected;

  assign ram_selected =
      (cpu_addr >= DMEM_BASE) &&
      (cpu_addr <  DMEM_END);

  assign uart_data_selected =
      (cpu_addr == UART_TX_ADDR);

  assign uart_status_selected =
      (cpu_addr == UART_TX_STATUS);

  assign timer_count_selected =
      (cpu_addr == TIMER_COUNT_ADDR);

  assign timer_compare_selected =
      (cpu_addr == TIMER_COMPARE_ADDR);

  assign timer_control_selected =
      (cpu_addr == TIMER_CONTROL_ADDR);


  // RAM interface

  logic        ram_read_en;
  logic        ram_write_en;
  logic [31:0] ram_read_data;

  assign ram_read_en =
      cpu_read_en && ram_selected;

  assign ram_write_en =
      cpu_write_en && ram_selected;

  dmem #(
      .INIT_FILE(DMEM_INIT_FILE)
  ) dmem_inst (
      .clk          (clk),
      .mem_read_en  (ram_read_en),
      .mem_write_en (ram_write_en),
      .addr         (cpu_addr),
      .write_data   (cpu_write_data),
      .byte_en      (cpu_byte_en),
      .read_data    (ram_read_data)
  );


  // UART interface

  assign uart_write_valid =
      cpu_write_en &&
      uart_data_selected &&
      !uart_busy;

  assign uart_write_data =
      cpu_write_data[7:0];


  // Timer interface

  assign timer_write_compare_en =
      cpu_write_en &&
      timer_compare_selected;

  assign timer_write_control_en =
      cpu_write_en &&
      timer_control_selected;

  assign timer_write_data =
      cpu_write_data;


  // CPU read-data mux

  always_comb begin
    cpu_read_data = 32'b0;

    if (ram_selected) begin
      cpu_read_data = ram_read_data;
    end else if (uart_status_selected) begin
      cpu_read_data = {31'b0, uart_busy};
    end else if (timer_count_selected) begin
      cpu_read_data = timer_count;
    end else if (timer_compare_selected) begin
      cpu_read_data = timer_compare;
    end else if (timer_control_selected) begin
      cpu_read_data = timer_control;
    end
  end


  // Address validity

  logic request_active;
  logic address_mapped;

  assign request_active =
      cpu_read_en || cpu_write_en;

  assign address_mapped =
      ram_selected           ||
      uart_data_selected     ||
      uart_status_selected   ||
      timer_count_selected   ||
      timer_compare_selected ||
      timer_control_selected;


  // Simulation checks

  always_ff @(posedge clk) begin
    if (!rst) begin
      if (request_active && !address_mapped) begin
        $error(
            "Unmapped bus access: addr=%08h read=%0b write=%0b",
            cpu_addr,
            cpu_read_en,
            cpu_write_en
        );
      end

      if (cpu_write_en &&
          uart_data_selected &&
          uart_busy) begin
        $error(
            "UART write attempted while transmitter busy: data=%02h",
            cpu_write_data[7:0]
        );
      end

      if (cpu_write_en &&
          uart_status_selected) begin
        $error(
            "Write attempted to read-only UART status register"
        );
      end

      if (cpu_write_en &&
          timer_count_selected) begin
        $error(
            "Write attempted to read-only timer count register"
        );
      end

      if (cpu_write_en &&
          (timer_compare_selected || timer_control_selected) &&
          (cpu_byte_en != 4'b1111)) begin
        $error(
            "Timer registers require 32-bit writes"
        );
      end
    end
  end

endmodule
