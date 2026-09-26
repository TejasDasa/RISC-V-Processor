.section .text
.globl _start

# ============================================================
# Waveform demo 03: taken branch flush
#
#   addi x1, x0, 5
#   addi x2, x0, 5
#   beq  x1, x2, target     taken (operands forwarded)
#   addi x3, x0, 99         wrong path: flushed from ID
#   addi x4, x0, 99         wrong path: flushed from IF
# target:
#   addi x5, x0, 7
#
# Branches resolve in EX. When the beq is in EX, the two
# sequential instructions behind it are already in ID and IF.
# ex_redirect loads the branch target into the PC and squashes
# IF/ID and ID/EX (valid = 0), so neither addi x..,99 ever writes
# a register. Branch penalty: two bubbles.
#
# Pipeline (cycle 0 = first cycle after reset; from the PIPE log):
#
#   cyc | pc | IF         | ID         | EX      | MEM     |
#   ----+----+------------+------------+---------+---------+---------------
#    3  | 0c | addi x3,99 | beq        | addi x2 | addi x1 |
#    4  | 10 | addi x4,99 | addi x3,99 | beq     | addi x2 | taken: REDIRECT -> 0x14
#    5  | 14 | addi x5,7  | bubble     | bubble  | beq     | x3, x4 squashed
#    6  | 18 | nop        | addi x5,7  | bubble  | bubble  |
#    7  | 1c | nop        | nop        | addi x5 | bubble  |
#
#   cycle 4: beq in EX with ex_rs1_forwarded = ex_rs2_forwarded = 5
#            (x1 from MEM/WB, x2 from EX/MEM), ex_branch_taken=1,
#            ex_take_branch=1, ex_redirect=1, ex_redirect_pc=0x14
#   cycle 5: pc_current=0x14; if_id_valid=0 and id_ex_valid=0 - the
#            two wrong-path addi instructions are gone
# ============================================================

_start:
    addi  x1, x0, 5
    addi  x2, x0, 5
    beq   x1, x2, target
    addi  x3, x0, 99
    addi  x4, x0, 99

target:
    addi  x5, x0, 7

    nop
    nop
    nop

done:
    jal   x0, done
