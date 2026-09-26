.section .text
.globl _start

# ============================================================
# Directed interrupt enable-gating and repeat test.
#
# Phase 1: timer IRQ pending, mie.MTIE=1, mstatus.MIE=0 -> not taken
# Phase 2: timer IRQ pending, mie.MTIE=0, mstatus.MIE=1 -> not taken
# Phase 3: set MTIE -> taken on the very next instruction.
#          The handler leaves the IRQ pending on its first two
#          entries, so the interrupt is re-taken immediately after
#          each MRET, always at the same (killed) instruction.
#          The third entry clears it; no further interrupts follow.
#
# The sled of 10 increments must execute exactly 10 times in
# total: no instruction is lost or duplicated.
# ============================================================

_start:
    addi  x7, x0, 0
    addi  x26, x0, 0
    addi  x30, x0, 0
    addi  x31, x0, 0

    lui   x25, 0x10000
    addi  x25, x25, 0x14        # TIMER_COMPARE 0x1000_0014

    la    x5, handler
    csrw  mtvec, x5

    sw    x0, 0(x25)            # compare = 0
    addi  x5, x0, 3
    sw    x5, 4(x25)            # ENABLE | IRQ_EN -> IRQ pending


    # ----------------------------------------------------------
    # Phase 1: MTIE=1, MIE=0
    # ----------------------------------------------------------

    addi  x5, x0, 0x80
    csrs  mie, x5

    addi  x6, x0, 20
1:
    addi  x6, x6, -1
    bne   x6, x0, 1b


    # ----------------------------------------------------------
    # Phase 2: MTIE=0, MIE=1
    # ----------------------------------------------------------

    csrw  mie, x0
    addi  x5, x0, 8
    csrs  mstatus, x5

    addi  x6, x0, 20
2:
    addi  x6, x6, -1
    bne   x6, x0, 2b

    addi  x29, x31, 0           # 0: nothing taken while gated


    # ----------------------------------------------------------
    # Phase 3: enable MTIE -> taken at sled[0], three times
    # ----------------------------------------------------------

    addi  x5, x0, 0x80
    csrs  mie, x5

sled:
    addi  x7, x7, 1
    addi  x7, x7, 1
    addi  x7, x7, 1
    addi  x7, x7, 1
    addi  x7, x7, 1
    addi  x7, x7, 1
    addi  x7, x7, 1
    addi  x7, x7, 1
    addi  x7, x7, 1
    addi  x7, x7, 1

    addi  x6, x0, 50
3:
    addi  x6, x6, -1            # no spurious re-entry here
    bne   x6, x0, 3b

    csrw  mstatus, x0

    la    x5, sled
    sub   x23, x26, x5          # 0: first mepc == sled

done:
    jal   x0, done


# ------------------------------------------------------------
# Handler (touches x24, x26, x28, x30, x31 only)
# ------------------------------------------------------------

handler:
    addi  x31, x31, 1
    csrr  x28, mepc

    addi  x24, x0, 1
    bne   x31, x24, 1f
    addi  x26, x28, 0           # first mepc
1:
    bne   x28, x26, 2f
    addi  x30, x30, 1           # same resume PC every entry
2:
    addi  x24, x0, 3
    blt   x31, x24, 3f          # entries 1-2: leave IRQ pending

    addi  x28, x0, -1
    sw    x28, 0(x25)           # entry 3: compare = max, clear IRQ
3:
    mret
