.section .text
.globl _start

_start:
    addi x1, x0, 5
    addi x2, x0, 7
    addi x3, x1, -2

done:
    jal x0, done