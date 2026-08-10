.section .text
.globl context_start

context_start:
    # a0 contains task 0's prepared stack pointer.
    mv sp, a0

    # Restore the fake context created by task_create().
    lw ra,  0(sp)
    lw s0,  4(sp)
    lw s1,  8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    lw s5, 24(sp)
    lw s6, 28(sp)
    lw s7, 32(sp)
    lw s8, 36(sp)
    lw s9, 40(sp)
    lw s10,44(sp)
    lw s11,48(sp)

    addi sp, sp, 52

    # ra was initialized to the task entry address.
    ret