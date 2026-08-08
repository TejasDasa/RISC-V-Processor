.section .text
.globl _start

_start:

    # ----------------------------------------------------------
    # 1. CSRRW
    #
    # Write 0x200 into mtvec.
    # Old mtvec should be returned in x6.
    # After reset, old mtvec = 0.
    # ----------------------------------------------------------

    addi x5, x0, 0x200

    csrrw x6, mtvec, x5

    # x6 should now contain old mtvec = 0


    # ----------------------------------------------------------
    # 2. CSRRS
    #
    # Set bit 3 in mstatus.
    #
    # mstatus starts at 0.
    # OR with 0x8 should produce 0x8.
    # Old mstatus should be returned in x7.
    # ----------------------------------------------------------

    addi x5, x0, 8

    csrrs x7, mstatus, x5

    # x7 should contain old mstatus = 0


    # ----------------------------------------------------------
    # 3. Pure CSR read
    #
    # csrr is a pseudo-instruction for:
    #
    # CSRRS rd, csr, x0
    #
    # Since rs1 = x0, the CSR must NOT be modified.
    # ----------------------------------------------------------

    csrr x8, mtvec
    csrr x9, mstatus


done:
    jal x0, done