.section .text
.globl _start

# ============================================================
# Directed MRET / mstatus interrupt-enable stack test.
#
# Trap entry: MPIE <= MIE, MIE <= 0
# MRET:       MIE  <= MPIE, MPIE <= 1, PC <= mepc
#
# mstatus.MIE = bit 3 (0x08), mstatus.MPIE = bit 7 (0x80).
# No interrupt source is enabled, so MIE=1 is harmless here.
# ============================================================

_start:
    addi  x31, x0, 0

    la    x5, handler
    csrw  mtvec, x5


    # ----------------------------------------------------------
    # 1. Trap with MIE=1: handler sees MIE=0, MPIE=1
    # ----------------------------------------------------------

    addi  x6, x0, 8
    csrs  mstatus, x6
    csrr  x7, mstatus           # 0x08

    ecall                       # handler: x8 = 0x80
    csrr  x9, mstatus           # after MRET: MIE=1, MPIE=1 -> 0x88


    # ----------------------------------------------------------
    # 2. Trap with MIE=0: MPIE captures 0, MRET keeps MIE=0
    # ----------------------------------------------------------

    csrw  mstatus, x0

    ecall                       # handler: x10 = 0x00
    csrr  x11, mstatus          # after MRET: MIE=0, MPIE=1 -> 0x80


    # ----------------------------------------------------------
    # 3. Direct MRET to a chosen target, mepc written just before
    #    (CSR write -> MRET back-to-back). Younger instructions
    #    behind MRET must be flushed.
    # ----------------------------------------------------------

    la    x5, mret_target
    csrw  mepc, x5
    mret
    addi  x12, x0, 0x12         # flushed (ID at MRET)
    addi  x13, x0, 0x13         # flushed (IF at MRET)
    addi  x14, x0, 0x14         # skipped

mret_target:
    addi  x15, x0, 0x15
    csrr  x16, mstatus          # MIE=MPIE(1), MPIE=1 -> 0x88

    csrw  mstatus, x0

done:
    jal   x0, done


# ------------------------------------------------------------
# ECALL handler: record mstatus per trap, return to mepc + 4.
# ------------------------------------------------------------

handler:
    addi  x31, x31, 1
    addi  x5, x0, 1
    bne   x31, x5, handler_second

    csrr  x8, mstatus           # first trap
    jal   x0, handler_return

handler_second:
    csrr  x10, mstatus          # second trap

handler_return:
    csrr  x5, mepc
    addi  x5, x5, 4
    csrw  mepc, x5
    mret
