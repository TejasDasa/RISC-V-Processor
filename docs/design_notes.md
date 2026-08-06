# RISC-V Processor Design Notes

## ALU

The ALU is combinational logic.

**Inputs** - Two 32-bit operands - ALU operation selector

**Output** - One 32-bit result

The ALU performs arithmetic, logical, shift, and comparison operations.
It contains no state and does not decode RISC-V instructions. The
decoder translates instructions into ALU control signals.

Supported operations: - ADD - SUB - AND - OR - XOR - SLL - SRL - SRA -
SLT - SLTU

------------------------------------------------------------------------

## Register File

The register file contains the 32 architectural RISC-V registers.

It contains both combinational and sequential logic.

**Inputs** - Clock - Write enable - Source register 1 address - Source
register 2 address - Destination register address - Destination register
write data

**Outputs** - Source register 1 data - Source register 2 data

Read ports are combinational. Writes occur on the positive clock edge
when write enable is asserted and the destination register is not x0.
Register x0 is hardwired to zero.

------------------------------------------------------------------------

## Immediate Generator

The Immediate Generator is combinational logic.

**Inputs** - Instruction - Immediate type

**Output** - 32-bit sign or zero extended immediate

Supported formats: - I-type - S-type - B-type - U-type - J-type

------------------------------------------------------------------------

## Program Counter

The Program Counter stores the current instruction address.

**Inputs** - Clock - Reset - Write enable - Next PC

**Output** - Current PC

On reset the PC returns to 0. When write enable is asserted, the PC
updates on the positive clock edge.

------------------------------------------------------------------------

## Instruction Memory

Instruction memory stores the executable program.

Instructions are addressed using byte addresses from the program
counter.

The memory is initialized from a generated instruction hex file and is
read-only during execution.

------------------------------------------------------------------------

## Data Memory

Data memory stores program variables, stack data, and global data.

The processor uses a Harvard architecture with separate instruction and
data memories.

Supported operations: - Byte loads/stores - Halfword loads/stores - Word
loads/stores

Byte enables support partial word writes. Memory is initialized from a
separate data-memory image. Processor addresses are translated into
local RAM indices.

------------------------------------------------------------------------

## Decoder

The decoder translates RISC-V instructions into datapath control
signals.

Outputs include: - Register addresses - ALU operation - Immediate type -
Branch operation - Writeback source - ALU input selection - Load type -
Store type - Memory enables - Register write enable - Jump control -
Illegal instruction detection

Supports the implemented RV32I instruction subset.

------------------------------------------------------------------------

## Branch Unit

The Branch Unit performs branch comparisons.

Supported branches: - BEQ - BNE - BLT - BGE - BLTU - BGEU

------------------------------------------------------------------------

## Core

The core integrates: - Program Counter - Instruction Memory - Decoder -
Register File - Immediate Generator - ALU - Branch Unit

The core executes one instruction at a time and exposes a generic memory
interface consisting of address, read/write enables, write data, byte
enables, and read data.

The core is independent of any specific peripherals.

------------------------------------------------------------------------

## Bus

The bus routes memory requests from the CPU.

Based on the requested address, it forwards accesses to: - Data Memory -
UART

The bus returns read data from the selected device and detects invalid
accesses during simulation.

------------------------------------------------------------------------

## UART Transmitter

The UART transmitter is a memory-mapped peripheral.

Software writes characters by storing a byte to the UART transmit
register.

The UART contains four states: - IDLE - START - DATA - STOP

Each frame consists of: - 1 start bit - 8 data bits (LSB first) - 1 stop
bit

A busy signal prevents overlapping transmissions.

------------------------------------------------------------------------

## System-on-Chip (SoC)

The SoC integrates the processor core, system bus, data memory, and UART
peripheral.

The CPU communicates with peripherals exclusively through memory-mapped
I/O.

### Memory Map

``` text
0x00000000 - Instruction Memory
0x00010000 - Data Memory
0x10000000 - UART TX Register
0x10000004 - UART Status Register
```

------------------------------------------------------------------------

## Software Runtime

Current software support includes: - Startup code (`crt0.S`) - Linker
script - Separate instruction and data memory images - `.data` -
`.bss` - `.rodata` - Stack initialization - Freestanding C execution -
Memory-mapped UART driver
