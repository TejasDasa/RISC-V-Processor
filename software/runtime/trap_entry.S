.section .text
.globl trap_entry
.extern trap_handler

trap_entry:
    addi sp, sp, -128

    sw ra,  0(sp)
    sw t0,  4(sp)
    sw t1,  8(sp)
    sw t2, 12(sp)

    sw a0, 16(sp)
    sw a1, 20(sp)
    sw a2, 24(sp)
    sw a3, 28(sp)
    sw a4, 32(sp)
    sw a5, 36(sp)
    sw a6, 40(sp)
    sw a7, 44(sp)

    sw t3, 48(sp)
    sw t4, 52(sp)
    sw t5, 56(sp)
    sw t6, 60(sp)

    sw tp, 64(sp)
    sw gp, 68(sp)

    sw s0,  72(sp)
    sw s1,  76(sp)
    sw s2,  80(sp)
    sw s3,  84(sp)
    sw s4,  88(sp)
    sw s5,  92(sp)
    sw s6,  96(sp)
    sw s7, 100(sp)
    sw s8, 104(sp)
    sw s9, 108(sp)
    sw s10,112(sp)
    sw s11,116(sp)

    csrr t0, mepc
    sw   t0, 120(sp)

    mv a0, sp

    call trap_handler

    mv sp, a0

    lw t0, 120(sp)
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

    lw s0,  72(sp)
    lw s1,  76(sp)
    lw s2,  80(sp)
    lw s3,  84(sp)
    lw s4,  88(sp)
    lw s5,  92(sp)
    lw s6,  96(sp)
    lw s7, 100(sp)
    lw s8, 104(sp)
    lw s9, 108(sp)
    lw s10,112(sp)
    lw s11,116(sp)

    addi sp, sp, 128

    mret