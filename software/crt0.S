.section .text.init
.globl _start

_start:
    addi sp, x0, 1008

    la t0, __bss_start
    la t1, __bss_end

clear_bss:
    bgeu t0, t1, bss_done
    sw   x0, 0(t0)
    addi t0, t0, 4
    jal  x0, clear_bss

bss_done:
    jal ra, main

halt:
    jal x0, halt