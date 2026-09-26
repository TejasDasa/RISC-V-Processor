.section .text
.globl _start

# ============================================================
# Waveform demo 01: forwarding chain
#
# Four back-to-back dependent ALU instructions. Every operand is
# produced by one of the previous two instructions, and all of
# them are resolved by forwarding: no stall, no bubble.
#
#   addi x1, x0, 5    x1 = 5
#   addi x2, x1, 3    rs1=x1 <- EX/MEM            x2 = 8
#   add  x3, x2, x1   rs1=x2 <- EX/MEM, rs2=x1 <- MEM/WB  x3 = 13
#   sub  x4, x3, x2   rs1=x3 <- EX/MEM, rs2=x2 <- MEM/WB  x4 = 5
#
# Expected pipeline (cycle 0 = first cycle after reset):
#
#   cycle | IF        | ID        | EX        | MEM       | WB
#   ------+-----------+-----------+-----------+-----------+----------
#     0   | addi x1   |           |           |           |
#     1   | addi x2   | addi x1   |           |           |
#     2   | add  x3   | addi x2   | addi x1   |           |
#     3   | sub  x4   | add  x3   | addi x2 * | addi x1   |
#     4   |           | sub  x4   | add  x3 **| addi x2   | addi x1
#     5   |           |           | sub  x4 **| add  x3   | addi x2
#
#   *  x1 forwarded from EX/MEM (produced one cycle earlier)
#   ** rs1 forwarded from EX/MEM, rs2 forwarded from MEM/WB
# ============================================================

_start:
    addi  x1, x0, 5
    addi  x2, x1, 3
    add   x3, x2, x1
    sub   x4, x3, x2

    nop
    nop
    nop

done:
    jal   x0, done
