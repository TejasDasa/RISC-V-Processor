0x0000_0000–0x0000_FFFF  Instruction memory
0x0001_0000–0x0001_03FF  Data memory
0x1000_0000               UART TX data
0x1000_0004               UART status

UART TX data: write byte
UART status: read word, bit 0 = busy