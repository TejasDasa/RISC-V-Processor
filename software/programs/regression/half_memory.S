.section .text
.globl _start

_start:
    lui  x1, 0x10

    lui  x2, 0xC
    addi x2, x2, -273
    # x2 = 0x0000BEEF

    sh   x2, 2(x1)

    lh   x3, 2(x1)
    lhu  x4, 2(x1)

done:
    jal x0, done