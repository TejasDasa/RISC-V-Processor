.section .text
.globl _start

# ============================================================
# Directed precise timer-interrupt sweep.
#
# A fixed "victim" block (ALU forwarding chains, load-use pairs,
# taken / not-taken branches, JAL, JALR, a CSR access, stores)
# computes a checksum in x20. It is run once with interrupts off
# to get a reference (x19), then ITER times with the timer
# compare moved one cycle later each time, so the interrupt lands
# on every instruction / stall / redirect position of the block.
#
# Precise interrupts mean every run produces the reference
# checksum: no older instruction is lost, the interrupted
# instruction re-executes exactly once after MRET, and no younger
# instruction commits before the handler.
#
# Register usage:
#   x1  link              x19 reference checksum
#   x5  temp              x20/x21, x11-x18 victim block
#   x8  ITER              x22 handler address (also mtvec value)
#   x9  0x8000_0007       x23/x24 victim block [start, end)
#   x10 DMEM base         x25 timer compare address
#   x26 iteration k       x27 error accumulator (must stay 0)
#   x28/x29 handler temp  x30 interrupts landing in the block
#   x31 interrupt count
# ============================================================

    .equ ITER,  48
    .equ DBASE, 2

_start:
    addi  x27, x0, 0
    addi  x30, x0, 0
    addi  x31, x0, 0

    lui   x10, 0x10             # DMEM 0x0001_0000
    lui   x25, 0x10000
    addi  x25, x25, 0x14        # TIMER_COMPARE 0x1000_0014

    la    x22, handler
    csrw  mtvec, x22
    la    x23, block_start
    la    x24, block_end

    lui   x9, 0x80000
    addi  x9, x9, 7             # expected mcause

    addi  x5, x0, -1
    sw    x5, 0(x25)            # compare = max: no IRQ yet
    addi  x5, x0, 3
    sw    x5, 4(x25)            # control = ENABLE | IRQ_EN

    addi  x5, x0, 0x80
    csrs  mie, x5               # MTIE


    # ----------------------------------------------------------
    # Reference run, MIE = 0
    # ----------------------------------------------------------

    jal   x1, block_start
    addi  x19, x20, 0

    addi  x5, x0, 8
    csrs  mstatus, x5           # MIE = 1

    addi  x26, x0, 0
    addi  x8, x0, ITER


    # ----------------------------------------------------------
    # Sweep
    # ----------------------------------------------------------

sweep_loop:
    lw    x5, -4(x25)           # TIMER_COUNT
    addi  x5, x5, DBASE
    add   x5, x5, x26
    sw    x5, 0(x25)            # compare = count + DBASE + k

    jal   x1, block_start

    xor   x5, x20, x19
    or    x27, x27, x5          # checksum must match reference

    addi  x26, x26, 1

wait_irq:
    blt   x31, x26, wait_irq    # exactly one IRQ per iteration

    blt   x26, x8, sweep_loop

    csrw  mstatus, x0

done:
    jal   x0, done


# ------------------------------------------------------------
# Victim block (subroutine, returns through x1)
# ------------------------------------------------------------

block_start:
    addi  x20, x0, 1
    addi  x11, x0, 3
    add   x20, x20, x11         # EX/MEM forward
    slli  x12, x20, 2
    xor   x20, x20, x12

    sw    x20, 0(x10)
    lw    x13, 0(x10)
    add   x20, x20, x13         # load-use
    lw    x14, 0(x10)
    addi  x14, x14, 7           # load-use
    add   x20, x20, x14

    beq   x0, x0, 1f            # taken branch
    addi  x20, x20, 0x100       # wrong path
1:
    bne   x0, x0, 2f            # not taken
    addi  x20, x20, 5
2:
    jal   x15, 3f               # JAL
    addi  x20, x20, 0x200       # wrong path
3:
    la    x16, 4f
    jalr  x17, 0(x16)           # JALR
    addi  x20, x20, 0x400       # wrong path
4:
    csrrw x18, mtvec, x22       # CSR read+write (same value)
    sub   x18, x18, x22         # 0
    add   x20, x20, x18

    sw    x20, 4(x10)
    lw    x21, 4(x10)
    sub   x21, x21, x20         # 0
    or    x20, x20, x21

    sub   x17, x17, x15         # link-register distance (constant)
    add   x20, x20, x17
block_end:
    jalr  x0, 0(x1)


# ------------------------------------------------------------
# Timer interrupt handler (only touches x27-x31)
# ------------------------------------------------------------

handler:
    csrr  x28, mcause
    xor   x28, x28, x9
    or    x27, x27, x28         # mcause must be 0x8000_0007

    csrr  x28, mstatus
    xori  x28, x28, 0x80
    or    x27, x27, x28         # in handler: MIE=0, MPIE=1

    csrr  x28, mepc
    bltu  x28, x23, 1f
    bgeu  x28, x24, 1f
    addi  x30, x30, 1           # interrupt landed inside block
1:
    addi  x28, x0, -1
    sw    x28, 0(x25)           # compare = max: clears the IRQ

    addi  x31, x31, 1
    mret
