.section .text
.globl _start

_start:
    addi x1, x0, 16

    addi x2, x0, 42
    sw   x2, 0(x1)

    addi x2, x0, 99
    sw   x2, 4(x1)

    lw   x3, 0(x1)
    lw   x4, 4(x1)

done:
    jal x0, done