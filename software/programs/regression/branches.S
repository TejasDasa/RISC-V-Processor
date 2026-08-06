.section .text
.globl _start

_start:
    addi x1, x0, 5
    addi x2, x0, 5

    beq x1, x2, equal
    addi x3, x0, 99

equal:
    addi x3, x0, 1

    bne x1, x2, wrong
    addi x4, x0, 2
    jal x0, done

wrong:
    addi x4, x0, 99

done:
    jal x0, done