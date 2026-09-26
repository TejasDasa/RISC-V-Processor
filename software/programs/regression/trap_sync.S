.section .text
.globl _start

# ============================================================
# Directed precise synchronous trap test (ECALL + illegal).
#
# For each trap:
#   - older instructions (load, CSR write) must have completed
#   - the trapping instruction has no register/memory effect
#   - younger instructions already fetched must be flushed
#   - mepc = PC of the trapping instruction
#   - mcause = 11 (ECALL) / 2 (illegal)
#
# Handlers return to mepc + 4.
# ============================================================

_start:
    addi  x26, x0, 0
    addi  x30, x0, 0
    addi  x31, x0, 0

    lui   x10, 0x10             # DMEM base 0x0001_0000
    addi  x14, x0, 0x5a         # memory sentinel
    sw    x14, 0(x10)
    sw    x14, 8(x10)


    # ----------------------------------------------------------
    # 1. ECALL
    # ----------------------------------------------------------

    lw    x8, 0(x10)            # older load, in WB at trap
    la    x5, handler_ecall
    csrw  mtvec, x5             # older CSR write, in MEM at trap

ecall_site:
    ecall
    addi  x7, x0, 0x77          # younger (ID at trap), flushed
    sw    x0, 0(x10)            # younger (IF at trap), flushed

    addi  x19, x0, 0x19         # proves execution resumed


    # ----------------------------------------------------------
    # 2. Illegal instructions
    # ----------------------------------------------------------

    la    x5, handler_ill
    csrw  mtvec, x5

    addi  x12, x0, 0x12
    addi  x9, x0, 0x99

    la    x29, ill_alu_site
ill_alu_site:
    .word 0xFE108633            # ADD x12,x1,x1 with funct7=0x7f
    addi  x15, x0, 1            # younger

    la    x29, ill_store_site
ill_store_site:
    .word 0x00953423            # SD x9, 8(x10) - not RV32
    addi  x11, x0, 0x11         # younger

    lw    x13, 8(x10)           # sentinel must be intact

done:
    jal   x0, done


# ------------------------------------------------------------
# Trap handlers
# ------------------------------------------------------------

handler_ecall:
    addi  x20, x7, 0            # 0: younger addi flushed
    lw    x23, 0(x10)           # 0x5a: younger store flushed
    addi  x24, x8, 0            # 0x5a: older load completed
    csrr  x21, mcause           # 11
    csrr  x22, mepc
    la    x5, ecall_site
    sub   x22, x22, x5          # 0: mepc == ECALL pc

    csrr  x5, mepc
    addi  x5, x5, 4
    csrw  mepc, x5
    mret

handler_ill:
    addi  x31, x31, 1           # trap count
    or    x26, x26, x11         # 0: younger addi never ran first
    csrr  x27, mcause           # 2
    csrr  x28, mepc
    sub   x28, x28, x29
    or    x30, x30, x28         # 0: mepc == illegal pc each time

    csrr  x5, mepc
    addi  x5, x5, 4
    csrw  mepc, x5
    mret
