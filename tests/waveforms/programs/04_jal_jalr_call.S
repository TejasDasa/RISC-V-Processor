.section .text
.globl _start

# ============================================================
# Waveform demo 04: JAL / JALR call and return
#
#   0x00  addi a0, x0, 20
#   0x04  jal  ra, func       ra = 0x08 (PC+4), jump to 0x10
#   0x08  addi a1, a0, 1      return lands here: a1 = 43
#   0x0c  j .                 halt
# func:
#   0x10  add  a0, a0, a0     a0 = 40
#   0x14  addi a0, a0, 2      a0 = 42
#   0x18  jalr x0, 0(ra)      return to ra = 0x08
#
# JAL and JALR both resolve in EX. JAL writes the link value
# (PC+4) through the normal WB path; JALR computes its target
# from the forwarded ra. Each redirect squashes the two
# sequential instructions behind it.
#
# Pipeline (cycle 0 = first cycle after reset; from the PIPE log):
#
#   cyc | pc | IF       | ID        | EX        | WB       |
#   ----+----+----------+-----------+-----------+----------+------------------
#    3  | 0c | j .      | addi a1   | jal       |          | REDIRECT -> 0x10
#    4  | 10 | add a0   | bubble    | bubble    | addi a0  |
#    5  | 14 | addi a0  | add a0    | bubble    | jal      | ra = 0x08 (PC+4)
#    6  | 18 | jalr     | addi a0   | add a0    |          | a0 forwarded
#    8  | 20 |          |           | jalr      | add a0   | REDIRECT -> ra = 0x08
#    9  | 08 | addi a1  | bubble    | bubble    | addi a0  | a0 = 42
#   11  |    |          |           | addi a1   |          | a1 = 43
#
#   cycle 3: ex_take_jump=1, ex_redirect_pc = 0x10 (func)
#   cycle 5: jal writes x1 = 0x08 through WB (wb_rd_addr=1)
#   cycle 8: ex_take_jalr=1, ex_rs1_forwarded = x1_ra = 0x08,
#            ex_redirect_pc = 0x08 (the instruction after the call)
# ============================================================

_start:
    addi  a0, x0, 20
    jal   ra, func
    addi  a1, a0, 1

done:
    jal   x0, done

func:
    add   a0, a0, a0
    addi  a0, a0, 2
    jalr  x0, 0(ra)
