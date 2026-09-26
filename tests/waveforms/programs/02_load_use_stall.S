.section .text
.globl _start

# ============================================================
# Waveform demo 02: load-use hazard
#
#   lui  x1, 0x10       x1 = 0x0001_0000 (DMEM base)
#   lw   x3, 0(x1)      x3 = 34 (base forwarded from EX/MEM)
#   addi x4, x3, 8      needs x3 in EX before the load has
#                       read memory -> one-cycle stall
#
# Load data is only available at the end of MEM, so the dependent
# addi cannot get it by EX/MEM forwarding. The hazard unit
# detects lw-in-EX / consumer-in-ID, freezes PC and IF/ID for one
# cycle and inserts a bubble into ID/EX. The addi then receives
# the load data by MEM/WB forwarding.
#
# Pipeline (cycle 0 = first cycle after reset; from the PIPE log):
#
#   cyc | pc | IF      | ID      | EX      | MEM     | WB      |
#   ----+----+---------+---------+---------+---------+---------+------------
#    2  | 08 | addi x4 | lw x3   | lui x1  |         |         |
#    3  | 0c | nop     | addi x4 | lw x3   | lui x1  |         | load_use_hazard=1
#    4  | 0c | nop     | addi x4 | bubble  | lw x3   | lui x1  | PC + IF/ID held
#    5  | 10 | nop     | nop     | addi x4 | bubble  | lw x3   | x3 via MEM/WB
#    7  |    |         |         |         |         | addi x4 | x4 = 42
#
#   cycle 3: lw in EX (id_ex_mem_read_en=1, id_ex_rd_addr=x3) and
#            addi in ID reads x3 -> load_use_hazard
#   cycle 4: pc_current and if_id_pc do not advance, id_ex_valid=0
#            (bubble). The lw reaches MEM and reads DMEM.
#   cycle 5: addi is in EX; fwd_rs1_src = MEM/WB, ex_rs1_forwarded
#            = 0x22 (the load data on wb_data)
# ============================================================

_start:
    lui   x1, 0x10
    lw    x3, 0(x1)
    addi  x4, x3, 8

    nop
    nop
    nop

done:
    jal   x0, done


.section .data
value:
    .word 34
