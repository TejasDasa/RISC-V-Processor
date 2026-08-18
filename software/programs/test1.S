.section .text.init
.globl _start

_start:
    lui  x1, 0x10          # x1 = 0x00010000

    addi x2, x0, 42
    sw   x2, 0(x1)

    lw   x3, 0(x1)         # x3 = 42
    addi x4, x3, 8         # x4 should = 50

halt:
    jal x0, halt