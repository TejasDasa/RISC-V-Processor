.section .text
.globl _start

_start:
    lui x1, 0x10

    addi x2, x0, 42
    sw   x2, 0(x1)
    lw   x3, 0(x1)

done:
    jal x0, done