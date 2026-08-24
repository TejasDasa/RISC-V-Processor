.section .text.init
.globl _start

_start:
    lui  x1, 0x10
    addi x2, x0, 42
    sw   x2, 0(x1)

    lw   x3, 0(x1)
    beq  x3, x2, target
    addi x4, x0, 99       # must be flushed

target:
    addi x5, x0, 7

halt:
    jal x0, halt