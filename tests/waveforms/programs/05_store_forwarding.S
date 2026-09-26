.section .text
.globl _start

# ============================================================
# Waveform demo 05: store-data forwarding
#
#   addi x1, x0, 42       store data, produced 2 instrs before sw
#   lui  x2, 0x10         store base, produced 1 instr before sw
#   sw   x1, 0(x2)        rs1 (base) <- EX/MEM, rs2 (data) <- MEM/WB
#   sb   x1, 5(x2)        byte store: lane 1, byte_en = 0010
#   lw   x3, 0(x2)        x3 = 42
#   lw   x4, 4(x2)        x4 = 0x2a00
#
# Both operands of the sw are still in flight when it is in EX.
# The forwarded rs2 value is latched into ex_mem_rs2_data, and in
# MEM the store unit aligns it to the byte lane and drives
# bus_write_data / bus_byte_en.
#
# Pipeline (cycle 0 = first cycle after reset; from the PIPE log):
#
#   cyc | EX       | MEM      | WB       |
#   ----+----------+----------+----------+----------------------------------
#    4  | sw       | lui x2   | addi x1  | base x2 <- EX/MEM, data x1 <- MEM/WB
#    5  | sb       | sw       | lui x2   | bus_write_en, addr 0x10000,
#       |          |          |          |   data 0x0000002a, byte_en 1111
#    6  | lw x3    | sb       | sw       | bus_write_en, addr 0x10005,
#       |          |          |          |   data 0x00002a00, byte_en 0010
#    8  |          |          | lw x3    | x3 = 0x2a
#    9  |          |          | lw x4    | x4 = 0x2a00
#
#   cycle 4: fwd_rs1_src = EX/MEM (x2 = 0x10000),
#            fwd_rs2_src = MEM/WB (x1 = 42 on wb_data)
#   cycle 5: ex_mem_rs2_data = 0x2a is the latched forwarded value
#
#   Note: bus_byte_en is only meaningful while bus_write_en = 1.
# ============================================================

_start:
    addi  x1, x0, 42
    lui   x2, 0x10
    sw    x1, 0(x2)
    sb    x1, 5(x2)
    lw    x3, 0(x2)
    lw    x4, 4(x2)

    nop
    nop
    nop

done:
    jal   x0, done


.section .data
buffer:
    .word 0
    .word 0
