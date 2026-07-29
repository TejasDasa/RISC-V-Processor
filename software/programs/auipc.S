.section .text
.globl _start

_start:
    addi x1, x0, 0

    # Place AUIPC at a known nonzero PC.
    auipc x5, 0x1

done:
    jal x0, done