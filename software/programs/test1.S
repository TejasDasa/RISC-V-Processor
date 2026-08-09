.section .text
.globl _start

_start:

    # ----------------------------------------------------------
    # Set trap handler address.
    # mtvec = 0x80
    # ----------------------------------------------------------

    addi t0, x0, 0x80
    csrw mtvec, t0


    # ----------------------------------------------------------
    # This instruction is valid and should execute.
    # ----------------------------------------------------------

    addi x5, x0, 7


    # ----------------------------------------------------------
    # Intentionally invalid instruction at address 0x0c.
    # ----------------------------------------------------------

    .word 0xffffffff


    # ----------------------------------------------------------
    # We should NOT automatically reach this instruction,
    # because MRET would return to the bad instruction again.
    # ----------------------------------------------------------

    addi x10, x0, 99

done:
    jal x0, done


    # ----------------------------------------------------------
    # Trap handler at 0x80
    # ----------------------------------------------------------

.org 0x80

trap_handler:

    # Prove handler executed.
    addi x10, x0, 42

    # Read trap cause.
    csrr x11, mcause

    # Read address of invalid instruction.
    csrr x12, mepc

handler_loop:
    jal x0, handler_loop