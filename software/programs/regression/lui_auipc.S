.section .text
.globl _start

_start:
    lui x1, 0x12345

    # This instruction is at address 0x04.
    auipc x2, 0x1

done:
    jal x0, done