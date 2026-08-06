# RV32I Processor and Bare-Metal Computing Platform

A synthesizable single-cycle RV32I processor written from scratch in SystemVerilog, capable of executing compiled C programs, supporting memory-mapped peripherals, and designed for FPGA deployment.

The project explores the complete hardware/software stack—from RTL design and verification to compiler toolchains, bare-metal software, and embedded system architecture.

---

# Highlights

## Processor

- Single-cycle RV32I implementation
- Harvard architecture
- Modular datapath and control design
- Fully synthesizable SystemVerilog

## Supported ISA

### Arithmetic & Logic

- ADD / SUB
- ADDI
- AND / OR / XOR
- SLL / SRL / SRA
- SLT / SLTU
- Immediate logical and comparison instructions

### Memory

- LB
- LBU
- LH
- LHU
- LW
- SB
- SH
- SW

### Control Flow

- BEQ
- BNE
- BLT
- BGE
- BLTU
- BGEU
- JAL
- JALR
- LUI
- AUIPC

---

# Current Features

The processor currently supports:

- Assembly execution
- Compiled freestanding C
- Function calls
- Stack frames
- Global variables
- Local variables
- `.text`
- `.data`
- `.bss`
- `.rodata`
- Separate instruction and data memories
- Memory-mapped UART
- Modular SoC bus
- Synthesizable UART transmitter
- Automatic ELF → IMEM / DMEM image generation

---

# Architecture

```
                +----------------+
                |      Core      |
                +--------+-------+
                         |
                  Generic Memory Bus
                         |
                +--------+--------+
                |                 |
              DMEM             UART
```

The processor core is intentionally independent of any peripherals.

Memory accesses are routed through a standalone bus module, allowing new peripherals to be added without modifying the CPU.

---

# Software Stack

The software toolchain includes:

- GNU RISC-V Toolchain
- crt0 startup code
- Custom linker script
- Freestanding C runtime
- UART runtime library
- Automatic ELF generation
- Separate IMEM / DMEM image generation

Current software executes directly on the processor without an operating system.

---

# Verification

Every hardware module is verified independently before integration.

Current verification includes:

- Self-checking SystemVerilog unit tests
- Integration tests
- Full software regression suite
- Assembly regression programs
- Compiled C regression programs

The repository currently contains tests for:

- ALU
- Register File
- Decoder
- Immediate Generator
- Branch Unit
- Data Memory
- UART
- Bus
- Complete SoC

---

# Example

Example UART program:

```c
#include "uart.h"

int main(void)
{
    uart_puts("Hello from RISC-V!\n");
    return 0;
}
```

The program is compiled using the RISC-V GNU toolchain, linked using a custom linker script, converted into separate instruction and data images, and executed entirely on the custom processor.

---

# FPGA Target

The processor is designed for FPGA deployment.

The current SoC consists of:

- RV32I CPU
- Instruction BRAM
- Data BRAM
- Memory-mapped UART

The same software currently used in simulation is intended to execute unchanged on FPGA hardware.

---

# Roadmap

The next major milestones are:

- Memory-mapped timer peripheral
- Machine-mode CSRs
- ECALL / MRET
- Timer interrupts
- Bare-metal scheduler
- Five-stage pipeline
- Hazard detection / forwarding
- Branch prediction
- FPGA bring-up
- Minimal kernel

---

# Technologies

- SystemVerilog
- Verilator
- GTKWave
- Python
- GNU RISC-V Toolchain
- Make
- Git
- Xilinx Vivado

---

# Repository Structure

```
rtl/
    common/
    core/
    soc/

software/
    runtime/
    programs/

tests/
    unit/
    integration/

scripts/
docs/
```

---

# Project Goals

This project is intended to demonstrate practical experience across the complete embedded hardware/software stack, including:

- RTL Design
- Computer Architecture
- Processor Verification
- FPGA Design
- Embedded Systems
- Compiler Toolchains
- Bare-Metal Programming
- SoC Design

Rather than implementing an isolated CPU core, the objective is to build a complete computing platform capable of running software directly on custom hardware.