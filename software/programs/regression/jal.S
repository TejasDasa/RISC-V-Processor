.section .text
.globl _start

_start:
    jal x1, target
    addi x2, x0, 99

target:
    addi x2, x0, 7

done:
    jal x0, done