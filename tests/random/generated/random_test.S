.section .text.init
.globl _start

_start:

    lui x20, 0x10
    addi x19, x0, 0

    addi x1, x0, 1
    addi x2, x0, 2
    addi x3, x0, 3
    addi x4, x0, 4
    addi x5, x0, 5
    addi x6, x0, 6
    addi x7, x0, 7
    addi x8, x0, 8
    addi x9, x0, 9
    addi x10, x0, 10
    addi x11, x0, 11
    addi x12, x0, 12
    addi x13, x0, 13
    addi x14, x0, 14
    addi x15, x0, 15

    jal x18, jal_target_0
    addi x11, x11, 1
    jal_target_0:
    addi x16, x0, 5
    addi x17, x0, 6
    bne x16, x17, branch_target_1
    addi x11, x11, 1
    branch_target_1:
    addi x16, x0, 5
    addi x17, x0, 6
    beq x16, x17, branch_target_2
    addi x10, x10, 1
    branch_target_2:
    jal x18, jal_target_3
    addi x1, x1, 1
    jal_target_3:
    add x2, x18, x10
    and x4, x2, x6
    add x11, x4, x7
    sltu x4, x11, x11
    or x5, x3, x15
    and x14, x10, x5
    sltu x5, x14, x6
    lw x8, 76(x20)
    sll x3, x8, x14
    sub x13, x3, x2
    jal x18, jal_target_4
    addi x1, x1, 1
    jal_target_4:
    lw x7, 88(x20)
    addi x16, x0, 5
    addi x17, x0, 6
    beq x16, x17, branch_target_5
    addi x5, x5, 1
    branch_target_5:
    xor x11, x8, x13
    sw x11, 84(x20)
    lw x6, 4(x20)
    addi x12, x6, -73
    or x11, x12, x5
    sw x11, 12(x20)
    lw x12, 4(x20)
    addi x15, x12, -59
    addi x16, x0, 5
    addi x17, x0, 6
    bne x16, x17, branch_target_6
    addi x2, x2, 1
    branch_target_6:
    and x4, x2, x2
    slt x7, x11, x4
    lw x3, 96(x20)
    add x15, x4, x5
    add x1, x15, x6
    sw x1, 144(x20)
    addi x16, x0, 1
    addi x17, x0, 2
    bge x16, x17, branch_target_7
    addi x2, x2, 1
    branch_target_7:
    lw x4, 4(x20)
    lw x15, 172(x20)
    or x10, x2, x15
    jal x31, helper
    and x10, x12, x10
    addi x16, x0, 1
    addi x17, x0, 2
    blt x16, x17, branch_target_8
    addi x13, x13, 1
    branch_target_8:
    sw x9, 192(x20)
    or x1, x15, x10
    addi x16, x0, 1
    addi x17, x0, 2
    blt x16, x17, branch_target_9
    addi x4, x4, 1
    branch_target_9:
    xor x7, x4, x4
    add x12, x1, x8
    sub x5, x1, x12
    slt x3, x5, x8
    sll x7, x14, x5
    lw x11, 148(x20)
    addi x16, x0, 2
    addi x17, x0, 1
    bgeu x16, x17, branch_target_10
    addi x6, x6, 1
    branch_target_10:
    sw x6, 236(x20)
    addi x16, x0, 2
    addi x17, x0, 1
    bge x16, x17, branch_target_11
    addi x14, x14, 1
    branch_target_11:
    jal x18, jal_target_12
    addi x15, x15, 1
    jal_target_12:
    sw x18, 72(x20)
    sw x11, 60(x20)
    and x6, x18, x12
    srl x11, x6, x3
    addi x10, x2, -41
    and x13, x2, x10
    sub x5, x8, x13
    srl x7, x9, x2
    sw x5, 68(x20)
    lw x7, 84(x20)
    addi x11, x7, 119
    addi x16, x0, 5
    addi x17, x0, 6
    bne x16, x17, branch_target_13
    addi x5, x5, 1
    branch_target_13:
    srl x7, x5, x14
    addi x16, x0, 1
    addi x17, x0, 2
    bgeu x16, x17, branch_target_14
    addi x13, x13, 1
    branch_target_14:
    and x12, x13, x9
    sll x14, x12, x4
    sw x14, 92(x20)
    or x3, x14, x3
    sub x9, x3, x9
    lw x2, 140(x20)
    lw x2, 96(x20)
    addi x16, x0, 2
    addi x17, x0, 1
    bge x16, x17, branch_target_15
    addi x15, x15, 1
    branch_target_15:
    sw x14, 88(x20)
    addi x16, x0, 1
    addi x17, x0, 2
    bge x16, x17, branch_target_16
    addi x10, x10, 1
    branch_target_16:
    sw x10, 152(x20)
    jal x31, helper
    jal x31, helper
    slt x12, x31, x6
    addi x16, x0, 2
    addi x17, x0, 1
    bltu x16, x17, branch_target_17
    addi x9, x9, 1
    branch_target_17:
    add x9, x9, x9
    xor x5, x9, x15
    jal x18, jal_target_18
    addi x15, x15, 1
    jal_target_18:
    sw x18, 184(x20)
    lw x13, 88(x20)
    addi x11, x13, -92
    sw x1, 212(x20)
    sw x11, 108(x20)
    jal x18, jal_target_19
    addi x9, x9, 1
    jal_target_19:
    addi x16, x0, 5
    addi x17, x0, 5
    beq x16, x17, branch_target_20
    addi x14, x14, 1
    branch_target_20:
    addi x16, x0, 1
    addi x17, x0, 2
    bgeu x16, x17, branch_target_21
    addi x13, x13, 1
    branch_target_21:
    addi x16, x0, 1
    addi x17, x0, 2
    blt x16, x17, branch_target_22
    addi x8, x8, 1
    branch_target_22:
    sltu x11, x8, x8
    and x3, x11, x11
    and x15, x3, x10
    or x10, x15, x9
    jal x18, jal_target_23
    addi x6, x6, 1
    jal_target_23:
    addi x16, x0, 5
    addi x17, x0, 5
    beq x16, x17, branch_target_24
    addi x2, x2, 1
    branch_target_24:
    lw x9, 240(x20)
    addi x3, x9, -21
    lw x14, 176(x20)
    addi x15, x14, 21
    addi x16, x0, 5
    addi x17, x0, 5
    bne x16, x17, branch_target_25
    addi x15, x15, 1
    branch_target_25:
    srl x4, x2, x15
    jal x31, helper
    xor x5, x31, x1
    addi x8, x5, 18
    sw x1, 232(x20)
    addi x2, x8, 29
    srl x10, x2, x11
    addi x16, x0, 1
    addi x17, x0, 2
    bge x16, x17, branch_target_26
    addi x2, x2, 1
    branch_target_26:
    sll x13, x2, x13
    jal x18, jal_target_27
    addi x9, x9, 1
    jal_target_27:
    lw x2, 0(x20)
    sw x2, 252(x20)
    addi x12, x2, -68
    jal x18, jal_target_28
    addi x14, x14, 1
    jal_target_28:
    sw x4, 16(x20)
    lw x6, 188(x20)
    addi x12, x6, -68
    sw x5, 124(x20)
    lw x14, 236(x20)
    addi x15, x14, -108
    addi x16, x0, 2
    addi x17, x0, 1
    bgeu x16, x17, branch_target_29
    addi x3, x3, 1
    branch_target_29:
    jal x18, jal_target_30
    addi x10, x10, 1
    jal_target_30:
    lw x4, 124(x20)
    addi x5, x4, -108
    xor x10, x12, x8
    jal x18, jal_target_31
    addi x6, x6, 1
    jal_target_31:
    addi x15, x18, -68
    and x14, x15, x10
    lw x14, 88(x20)
    addi x13, x14, -9
    slt x1, x1, x2
    srl x8, x5, x1
    jal x18, jal_target_32
    addi x7, x7, 1
    jal_target_32:
    jal x31, helper
    xor x5, x31, x11
    and x4, x12, x14
    sw x4, 76(x20)
    lw x7, 32(x20)
    addi x3, x7, 114
    sltu x12, x3, x5
    slt x8, x12, x12
    addi x16, x0, 5
    addi x17, x0, 5
    beq x16, x17, branch_target_33
    addi x15, x15, 1
    branch_target_33:
    and x7, x15, x4
    slt x5, x4, x15
    or x11, x5, x9
    srl x6, x11, x2
    jal x31, helper
    sw x31, 240(x20)
    sub x1, x31, x31
    lw x1, 108(x20)
    addi x4, x1, -106
    lw x15, 68(x20)
    addi x16, x0, 2
    addi x17, x0, 1
    bge x16, x17, branch_target_34
    addi x5, x5, 1
    branch_target_34:
    addi x16, x0, 1
    addi x17, x0, 2
    bltu x16, x17, branch_target_35
    addi x1, x1, 1
    branch_target_35:
    add x7, x1, x2
    jal x18, jal_target_36
    addi x14, x14, 1
    jal_target_36:
    sw x18, 124(x20)
    addi x16, x0, 2
    addi x17, x0, 1
    bltu x16, x17, branch_target_37
    addi x15, x15, 1
    branch_target_37:
    slt x14, x15, x14
    addi x16, x0, 2
    addi x17, x0, 1
    bgeu x16, x17, branch_target_38
    addi x1, x1, 1
    branch_target_38:
    or x5, x1, x5
    add x4, x8, x4
    jal x18, jal_target_39
    addi x1, x1, 1
    jal_target_39:
    sw x18, 108(x20)
    lw x4, 44(x20)
    srl x14, x7, x4
    sub x7, x14, x15
    addi x16, x0, 2
    addi x17, x0, 1
    bltu x16, x17, branch_target_40
    addi x9, x9, 1
    branch_target_40:
    srl x4, x9, x15
    xor x3, x4, x4
    addi x2, x5, 115
    sltu x5, x2, x8
    addi x16, x0, 5
    addi x17, x0, 5
    bne x16, x17, branch_target_41
    addi x1, x1, 1
    branch_target_41:
    slt x6, x1, x14
    sw x6, 24(x20)
    addi x16, x0, 1
    addi x17, x0, 2
    bge x16, x17, branch_target_42
    addi x15, x15, 1
    branch_target_42:
    addi x16, x0, 5
    addi x17, x0, 6
    beq x16, x17, branch_target_43
    addi x12, x12, 1
    branch_target_43:
    addi x16, x0, 5
    addi x17, x0, 6
    bne x16, x17, branch_target_44
    addi x9, x9, 1
    branch_target_44:
    addi x16, x0, 1
    addi x17, x0, 2
    bltu x16, x17, branch_target_45
    addi x6, x6, 1
    branch_target_45:
    sw x6, 220(x20)
    sw x6, 80(x20)
    addi x16, x0, 2
    addi x17, x0, 1
    bltu x16, x17, branch_target_46
    addi x11, x11, 1
    branch_target_46:
    xor x14, x5, x14

halt:
    jal x0, halt

helper:
    addi x19, x19, 1
    jalr x0, 0(x31)

