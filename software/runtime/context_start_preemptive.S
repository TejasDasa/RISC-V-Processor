.section .text
.globl context_start_preemptive

context_start_preemptive:

    mv sp, a0

    lw   t0, 120(sp)
    csrw mepc, t0

    lw ra,  0(sp)
    lw t0,  4(sp)
    lw t1,  8(sp)
    lw t2, 12(sp)

    lw a0, 16(sp)
    lw a1, 20(sp)
    lw a2, 24(sp)
    lw a3, 28(sp)
    lw a4, 32(sp)
    lw a5, 36(sp)
    lw a6, 40(sp)
    lw a7, 44(sp)

    lw t3, 48(sp)
    lw t4, 52(sp)
    lw t5, 56(sp)
    lw t6, 60(sp)

    lw tp, 64(sp)
    lw gp, 68(sp)

    lw s0, 72(sp)
    lw s1, 76(sp)
    lw s2, 80(sp)
    lw s3, 84(sp)
    lw s4, 88(sp)
    lw s5, 92(sp)
    lw s6, 96(sp)
    lw s7, 100(sp)
    lw s8, 104(sp)
    lw s9, 108(sp)
    lw s10,112(sp)
    lw s11,116(sp)

    addi sp, sp, 128

    mret