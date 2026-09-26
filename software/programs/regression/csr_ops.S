.section .text
.globl _start

# ============================================================
# Directed Zicsr completeness test.
#
#   - CSRRC, CSRRWI, CSRRSI, CSRRCI
#   - no write for CSRRS/CSRRC with rs1=x0 and CSRRSI/CSRRCI with
#     zimm=0 (the rs1 field is zero in both cases)
#   - mscratch read/write, mtval reads zero
#   - mstatus WARL: only MIE/MPIE writable, MPP reads as M (11)
#   - access to an unimplemented CSR raises an illegal-instruction
#     trap with no register write-back
# ============================================================

_start:
    addi  x30, x0, 0
    addi  x31, x0, 0

    la    x5, handler
    csrw  mtvec, x5


    # ----------------------------------------------------------
    # 1. mscratch + CSRRC (register form)
    # ----------------------------------------------------------

    addi  x6, x0, 0x5a5
    csrw  mscratch, x6
    csrr  x7, mscratch          # 0x5a5

    addi  x6, x0, 0x0f0
    csrrc x8, mscratch, x6      # x8 = 0x5a5, mscratch = 0x505
    csrr  x9, mscratch          # 0x505
    csrrc x10, mscratch, x0     # rs1=x0: no write, x10 = 0x505


    # ----------------------------------------------------------
    # 2. Immediate forms
    # ----------------------------------------------------------

    csrrwi x11, mscratch, 0x1f  # x11 = 0x505, mscratch = 0x1f
    csrrsi x12, mscratch, 0     # zimm=0: no write, x12 = 0x1f
    csrrci x13, mscratch, 0x3   # x13 = 0x1f, mscratch = 0x1c
    csrrsi x14, mscratch, 0x2   # x14 = 0x1c, mscratch = 0x1e
    csrr   x15, mscratch        # 0x1e
    addi   x16, x15, 1          # forwarded: 0x1f


    # ----------------------------------------------------------
    # 3. mstatus WARL and mtval
    #    (no interrupt source is enabled, so MIE=1 is harmless)
    # ----------------------------------------------------------

    addi  x6, x0, -1
    csrw  mstatus, x6
    csrr  x17, mstatus          # MPP|MPIE|MIE = 0x1888
    csrw  mstatus, x0
    csrr  x18, mstatus          # MPP = 0x1800

    csrw  mtval, x6
    csrr  x19, mtval            # 0


    # ----------------------------------------------------------
    # 4. Unimplemented CSRs trap as illegal instructions
    # ----------------------------------------------------------

    addi  x20, x0, 0x20
    addi  x22, x0, 0x22

    la    x29, bad_csr_write
bad_csr_write:
    csrrw x20, 0x7c0, x6        # must not write x20
    addi  x21, x0, 0x21

    la    x29, bad_csr_read
bad_csr_read:
    csrrs x22, 0xfc0, x0        # read-only form, still illegal
    addi  x23, x0, 0x23

done:
    jal   x0, done


# ------------------------------------------------------------
# Illegal-instruction handler
# ------------------------------------------------------------

handler:
    addi  x31, x31, 1
    csrr  x27, mcause           # 2
    csrr  x28, mepc
    sub   x28, x28, x29
    or    x30, x30, x28         # 0: mepc == faulting PC each time

    csrr  x28, mepc
    addi  x28, x28, 4
    csrw  mepc, x28
    mret
