.section .text.init
.globl _start

.extern main
.extern trap_entry

_start:
    # Initialize stack pointer.
    la sp, __stack_top

    # Clear .bss
    la t0, __bss_start
    la t1, __bss_end

clear_bss:
    bgeu t0, t1, bss_done
    sw   x0, 0(t0)
    addi t0, t0, 4
    jal  x0, clear_bss

bss_done:
    # Install machine-mode trap handler.
    la   t0, trap_entry
    csrw mtvec, t0

    # Enter C program.
    jal ra, main

halt:
    jal x0, halt