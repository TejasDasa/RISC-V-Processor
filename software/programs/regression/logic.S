.section .text
.globl _start

_start:
    addi x1, x0, 12
    addi x2, x0, 10

    and x3, x1, x2
    or  x4, x1, x2
    xor x5, x1, x2

    andi x6, x1, 10
    ori  x7, x1, 1
    xori x8, x1, 15

done:
    jal x0, done