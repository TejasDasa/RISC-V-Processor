# RV32I Processor and Bare-Metal Computing Platform

A complete RV32I processor built from scratch in SystemVerilog, targeting FPGA implementation and capable of executing compiled C programs, memory-mapped peripherals, and eventually a minimal bare-metal runtime and machine-mode operating system.

This project is intended as a full-stack exploration of computer architecture, digital design, embedded systems, and low-level software—from RTL all the way to bare-metal execution.

---

## Project Goals

The long-term goal is not simply to build a RISC-V CPU, but to build an entire computer capable of:

- Executing the complete RV32I ISA
- Running compiled assembly and freestanding C
- Interfacing with real peripherals through memory-mapped I/O
- Booting on an FPGA
- Supporting machine-mode exceptions and interrupts
- Providing the foundation for a minimal bare-metal runtime and kernel

---

# Architecture

The processor implements a modular RV32I microarchitecture consisting of:

- Program Counter (PC)
- Instruction Memory
- Decoder / Control Unit
- Register File
- Immediate Generator
- Arithmetic Logic Unit (ALU)
- Branch Unit
- Data Memory
- Writeback Logic

Each component is developed independently with self-checking SystemVerilog testbenches before integration into the processor.

---

# ISA Support

The target ISA is the complete RV32I instruction set.

### Arithmetic

- ADD
- SUB
- ADDI
- AND
- OR
- XOR
- SLL
- SRL
- SRA
- SLT
- SLTU
- ANDI
- ORI
- XORI
- SLLI
- SRLI
- SRAI
- SLTI
- SLTIU

### Memory

- LB
- LH
- LW
- LBU
- LHU
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

### System

Planned support:

- ECALL
- MRET
- CSR instructions
- Machine-mode traps
- Timer interrupts

---

# Verification Strategy

Each RTL block is verified independently before processor integration.

Current verification includes:

- Directed SystemVerilog unit tests
- Self-checking testbenches
- End-to-end instruction execution tests
- Assembly regression programs

Eventually the project will execute a growing suite of assembly programs compiled using the RISC-V GNU toolchain.

---

# Software Toolchain

Programs are developed using the RISC-V GNU toolchain.

```
Assembly / C
      │
      ▼
 GNU Toolchain
      │
      ▼
     ELF
      │
      ▼
 Binary Image
      │
      ▼
Hex Memory Image
      │
      ▼
Instruction Memory
      │
      ▼
Processor Execution
```

The build flow includes:

- GNU Assembler
- GNU Linker
- ELF generation
- Binary extraction
- Hex conversion
- Automatic loading into instruction memory

---

# Freestanding C Execution

After RV32I support is complete, the processor will execute compiled freestanding C programs.

Planned software components include:

- Startup assembly (crt0)
- Linker script
- Stack initialization
- C runtime support
- Function calls
- Local/global variables
- Recursion
- Static data

Example target:

```c
int add(int a, int b)
{
    return a + b;
}

int main(void)
{
    volatile int result = add(5, 7);

    while (1) {}
}
```

---

# Memory-Mapped I/O

The processor will expose peripherals through a memory-mapped interface.

Planned peripherals:

- UART
- GPIO
- Timer
- Performance Counters

Example:

```c
#define UART_TX (*(volatile unsigned int *)0x10000000)

UART_TX = 'H';
```

---

# FPGA Deployment

The processor is designed for synthesis on Xilinx FPGAs.

Planned FPGA system:

```
                 +----------------+
                 |    RV32I CPU   |
                 +-------+--------+
                         |
               Memory-Mapped Bus
                         |
      +---------+--------+---------+
      |         |                  |
   BRAM      UART TX/RX         Timer
```

Programs will be loaded into Block RAM and executed directly on hardware.

---

# Machine Mode

The long-term architecture includes support for the RISC-V privileged specification.

Planned CSRs include:

- mstatus
- mtvec
- mepc
- mcause
- mie
- mip

Supported functionality:

- ECALL
- MRET
- Exception handling
- Timer interrupts
- External interrupts

---

# Bare-Metal Runtime

The final goal is to support a minimal embedded software environment.

Planned features:

- Startup code
- Interrupt handlers
- UART driver
- Timer driver
- Cooperative scheduler
- Simple memory allocator
- Minimal libc support

This creates a complete bare-metal software stack capable of running directly on the custom processor without an operating system.

---

# Future Extensions

Potential architectural improvements include:

- Five-stage pipeline
- Hazard detection and forwarding
- Branch prediction
- Instruction/data caches
- Performance counters
- Hardware accelerator interface
- Custom RISC-V instructions
- AI accelerator coprocessor
- Simple kernel and multitasking support

---

# Technologies

- SystemVerilog
- Verilator
- GTKWave
- RISC-V GNU Toolchain
- Xilinx Vivado
- Python
- Make
- Git

---

# Learning Objectives

This project is intended to develop experience across the entire hardware/software stack:

- RTL Design
- Computer Architecture
- Instruction Set Design
- Processor Verification
- Embedded Systems
- FPGA Design
- Toolchain Development
- Bare-Metal Programming
- Operating System Fundamentals

Rather than focusing solely on processor implementation, the project aims to demonstrate how hardware, compilers, runtime software, and embedded systems integrate into a complete computing platform.