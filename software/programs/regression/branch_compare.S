.section .text
.globl _start

_start:
    addi x1, x0, -1
    addi x2, x0, 1

    blt x1, x2, signed_less
    addi x3, x0, 99

signed_less:
    addi x3, x0, 1

    bltu x1, x2, unsigned_less
    addi x4, x0, 2
    jal x0, done

unsigned_less:
    addi x4, x0, 99

done:
    jal x0, done