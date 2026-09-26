.section .text
.globl _start

# ============================================================
# Waveform demo 06: timer interrupt -> trap entry -> MRET
#
# Setup arms the machine timer to fire a few cycles into a sled
# of eight "addi x10, x10, 1". The interrupt is taken on whichever
# sled instruction is in EX at that moment:
#
#   - that instruction is killed and becomes mepc
#   - older instructions (in MEM/WB) still complete
#   - the younger ones in IF/ID are flushed
#   - PC -> mtvec, mcause = 0x8000_0007, MIE -> MPIE, MIE = 0
#
# The handler records mcause/mepc, clears the timer by pushing
# compare to the maximum, and executes MRET: PC -> mepc and MIE is
# restored. The killed addi executes again, so x10 ends at exactly
# 8: no instruction is lost or duplicated.
#
# Pipeline (cycle 0 = first cycle after reset; from the PIPE log).
# sled[n] is the n-th "addi x10, x10, 1", sled[0] at 0x40.
#
#   cyc | pc | IF      | ID      | EX       | MEM           | WB            |
#   ----+----+---------+---------+----------+---------------+---------------+-----------------
#   22  | 54 | sled[5] | sled[4] | sled[3]  | sled[2]       | sled[1]       | IRQ: trap_enter,
#       |    |         |         |          |               |               |   REDIRECT -> mtvec 0x68
#   23  | 68 | csrr    | bubble  | bubble   | TRAP sled[3]  | sled[2]       | mepc=0x4c, x10=3
#   24  | 6c | csrr    | csrr    | bubble   | bubble        | TRAP sled[3]  | retire_interrupt
#   25  |    |         |         | csrr x20 |               |               | handler runs
#   28  |    |         | mret    | sw x28   |               |               | compare = max
#   29  | 80 |         |         | mret     | sw x28        |               | REDIRECT -> mepc 0x4c
#   30  | 4c | sled[3] | bubble  | bubble   | mret          |               | MIE restored
#   32  |    |         |         | sled[3]  |               |               | re-executed once
#
#   cycle 22: timer_count reaches timer_compare -> cpu_irq = 1;
#             MIE=1 and MTIE=1 -> ex_irq = 1 on sled[3] in EX.
#             sled[1] and sled[2] (older) still write back;
#             sled[4] and sled[5] (younger) are squashed.
#   cycle 23: mepc = 0x4c, mcause = 0x8000_0007, mstatus.MIE = 0
#   cycle 29: ex_take_mret = 1, ex_redirect_pc = mepc = 0x4c
#   end:      x10 = 8, every increment executed exactly once
# ============================================================

    .equ IRQ_DELAY, 6

_start:
    la    x5, handler
    csrw  mtvec, x5

    lui   x25, 0x10000
    addi  x25, x25, 0x14        # TIMER_COMPARE 0x1000_0014

    addi  x5, x0, -1
    sw    x5, 0(x25)            # compare = max (no IRQ yet)
    addi  x5, x0, 3
    sw    x5, 4(x25)            # TIMER_CONTROL = ENABLE | IRQ_EN

    addi  x5, x0, 0x80
    csrs  mie, x5               # mie.MTIE = 1
    addi  x5, x0, 8
    csrs  mstatus, x5           # mstatus.MIE = 1

    lw    x5, -4(x25)           # TIMER_COUNT
    addi  x5, x5, IRQ_DELAY
    sw    x5, 0(x25)            # compare = count + IRQ_DELAY

sled:
    addi  x10, x10, 1
    addi  x10, x10, 1
    addi  x10, x10, 1
    addi  x10, x10, 1
    addi  x10, x10, 1
    addi  x10, x10, 1
    addi  x10, x10, 1
    addi  x10, x10, 1

    csrw  mstatus, x0

done:
    jal   x0, done


handler:
    csrr  x20, mcause           # 0x8000_0007
    csrr  x21, mepc             # PC of the killed sled instruction
    addi  x28, x0, -1
    sw    x28, 0(x25)           # compare = max: clears the IRQ
    mret
