.section .text
.globl _start

_start:
    # Test BEQ: should be taken
    addi x1, x0, 5
    addi x2, x0, 5
    beq  x1, x2, beq_pass
    addi x10, x0, 1          # failure code

beq_pass:
    addi x3, x0, 10

    # Test BNE: should be taken
    bne  x1, x3, bne_pass
    addi x10, x0, 2          # failure code

bne_pass:
    addi x4, x0, 20

    # Test BLT: should be taken
    blt  x3, x4, blt_pass
    addi x10, x0, 3          # failure code

blt_pass:
    addi x5, x0, 30

    # Test BGE: should be taken
    bge  x5, x4, bge_pass
    addi x10, x0, 4          # failure code

bge_pass:
    # Test BLTU: should be taken
    addi x6, x0, 1
    addi x7, x0, 2
    bltu x6, x7, bltu_pass
    addi x10, x0, 5          # failure code

bltu_pass:
    # Test BGEU: should be taken
    bgeu x7, x6, bgeu_pass
    addi x10, x0, 6          # failure code

bgeu_pass:
    # Test a branch that should NOT be taken
    beq  x6, x7, failure
    addi x8, x0, 42

    # Success marker
    addi x9, x0, 1
    jal  x0, done

failure:
    addi x10, x0, 99

done:
    jal x0, done