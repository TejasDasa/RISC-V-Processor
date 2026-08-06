package soc_pkg;

  localparam logic [31:0] DMEM_BASE        = 32'h0001_0000;
  localparam logic [31:0] DMEM_END         = 32'h0001_0400;

  localparam logic [31:0] UART_TX_ADDR     = 32'h1000_0000;
  localparam logic [31:0] UART_TX_STATUS = 32'h1000_0004;

  localparam logic [31:0] TIMER_COUNT_ADDR = 32'h1000_0010;

endpackage
