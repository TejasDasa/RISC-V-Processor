.section .text
.globl _start

_start:
    addi x1, x0, 20
    addi x2, x0, 8
    sub x3, x1, x2

done:
    jal x0, done