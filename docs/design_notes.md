Design Notes

ALU:

The ALU is combinational logic.
It takes a two 32-bit inputs and an operation selector.
It produces one 32-bit output.
It does not store state.
It does not know about RISC-V instructions directly.
The decoder will eventually translate instruction into ALU operations.

Regfile:

The Regfile is combinational and sequential logic.

Inputs: clock, write enable, register 1 select, register 2 select, destination register select, and destination register data

Outputs: new register 1 data and new register 2 data.

Combination Logic -> register 1 and 2 either are equal to 0 if the register address is 0 or equal to the data value at the source address inputs.

Sequential Logic -> at the positive clock edge, if write enable and destination address select are not equal to 0 then destination register data is written into the destination address of the register array.