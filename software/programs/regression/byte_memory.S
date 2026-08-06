.section .text
.globl _start

_start:
    lui x1, 0x10

    addi x2, x0, -128
    sb   x2, 1(x1)

    lb   x3, 1(x1)
    lbu  x4, 1(x1)

done:
    jal x0, done