.section .text
.globl _start

_start:
    addi x1, x0, -1
    addi x2, x0, 1

    slt  x3, x1, x2
    sltu x4, x1, x2

    slti  x5, x2, 2
    sltiu x6, x2, 2

done:
    jal x0, done