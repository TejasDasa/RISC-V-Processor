.section .text
.globl _start

_start:
    addi a0, x0, 20
    addi a1, x0, 8
    jal  ra, add_values

done:
    jal x0, done

add_values:
    add a0, a0, a1
    jalr x0, 0(ra)