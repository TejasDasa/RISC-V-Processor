.section .text
.globl _start

# ============================================================
# Directed CSR pipeline hazard test.
#
# CSRs are read and written in EX, so a CSR instruction in EX
# must observe every older CSR write, and its old-value result
# must be forwarded like any other ALU result.
#
# Interrupts stay disabled (mstatus is never written) and no
# instruction here traps.
# ============================================================

_start:

    # ----------------------------------------------------------
    # 1. Back-to-back CSR write/read on the same CSR
    # ----------------------------------------------------------

    addi  x5, x0, 0x111
    addi  x8, x0, 0x222

    csrrw x6, mepc, x5          # x6 = 0     (reset value)
    csrrw x7, mepc, x8          # x7 = 0x111 (previous write)
    csrr  x9, mepc              # x9 = 0x222


    # ----------------------------------------------------------
    # 2. Back-to-back CSRRS read-modify-write
    # ----------------------------------------------------------

    addi  x1, x0, 1
    addi  x2, x0, 2

    csrrw x0, mcause, x0        # mcause = 0
    csrrs x0, mcause, x1        # mcause = 1
    csrrs x10, mcause, x2       # x10 = 1, mcause = 3
    csrrs x11, mcause, x0       # x11 = 3, rs1=x0: no write


    # ----------------------------------------------------------
    # 3. CSR old value forwarded to a dependent ALU op
    #    at distance 1 (EX/MEM), 2 (MEM/WB), 3 (WB->ID)
    # ----------------------------------------------------------

    csrr  x12, mcause           # 3
    addi  x13, x12, 0x10        # 0x13

    csrr  x14, mepc             # 0x222
    nop
    addi  x15, x14, 1           # 0x223

    csrr  x16, mepc             # 0x222
    nop
    nop
    addi  x17, x16, 2           # 0x224


    # ----------------------------------------------------------
    # 4. CSR write data forwarded from the previous ALU op
    # ----------------------------------------------------------

    addi  x18, x0, 0x3c0
    csrrw x0, mtvec, x18
    csrr  x19, mtvec            # 0x3c0


    # ----------------------------------------------------------
    # 5. Load-use hazard into CSR rs1
    # ----------------------------------------------------------

    lui   x20, 0x10             # DMEM base 0x0001_0000
    addi  x21, x0, 0x5a5
    sw    x21, 0(x20)
    lw    x22, 0(x20)
    csrrw x23, mcause, x22      # stall; x23 = 3 (old value)
    csrr  x24, mcause           # 0x5a5


    # ----------------------------------------------------------
    # 6. CSR result used directly as store data
    # ----------------------------------------------------------

    csrr  x25, mtvec
    sw    x25, 4(x20)
    lw    x26, 4(x20)           # 0x3c0


    # ----------------------------------------------------------
    # 7. csrrw with rd = x0 still writes the CSR
    # ----------------------------------------------------------

    csrrw x0, mepc, x21
    csrr  x27, mepc             # 0x5a5

done:
    jal   x0, done
