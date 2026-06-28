Design Notes

ALU:

The ALU is combinational logic.
It takes a two 32-bit inputs and an operation selector.
It produces one 32-bit output.
It does not store state.
It does not know about RISC-V instructions directly.
The decoder will eventually translate instruction into ALU operations.