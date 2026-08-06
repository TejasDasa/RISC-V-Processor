.section .text
.globl _start

_start:
    addi x1, x0, 1
    addi x2, x0, 3

    sll  x3, x1, x2
    slli x4, x1, 4

    srli x5, x4, 2

    addi x6, x0, -16
    srai x7, x6, 2

done:
    jal x0, done