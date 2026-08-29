# RV32I Processor and FPGA SoC

A custom RV32I processor and bare-metal SoC written from scratch in SystemVerilog, featuring a **five-stage pipelined CPU**, memory-mapped peripherals, machine-mode interrupts, preemptive multitasking, and deployment on a **Digilent Cora Z7-07S (Zynq-7000)** FPGA.

The project spans the complete hardware/software stack: CPU microarchitecture, RTL verification, bare-metal software, FPGA implementation, and hardware/software integration.

---

# Highlights

## Processor

- Five-stage **IF / ID / EX / MEM / WB** RV32I pipeline
- EX/MEM and MEM/WB data forwarding
- WB-to-ID register bypass
- Load-use hazard detection and pipeline stalls
- Branch and store-data forwarding
- Control-hazard detection and pipeline flushing
- Machine-mode CSRs, traps, and interrupts
- Harvard instruction/data memory architecture
- Fully synthesizable SystemVerilog

## Supported ISA

Supports the RV32I integer instruction set, including:

- Integer arithmetic and logical operations
- Immediate arithmetic and logic
- Shifts and signed/unsigned comparisons
- Byte, halfword, and word loads/stores
- Conditional branches
- JAL / JALR
- LUI / AUIPC
- CSR operations
- ECALL / MRET

---

# CPU Microarchitecture

The current processor uses a classic five-stage in-order pipeline:

```text
        IF          ID          EX          MEM         WB
        |           |           |           |           |
 PC -> IMEM -> IF/ID -> Decode -> ID/EX -> ALU -> EX/MEM -> Memory -> MEM/WB
                        Regfile           Branch                    Regfile
```

Pipeline features currently implemented and verified:

- IF/ID, ID/EX, EX/MEM, and MEM/WB pipeline registers
- EX/MEM → EX forwarding
- MEM/WB → EX forwarding
- WB → ID register bypass
- Forwarding into ALU, branch, JALR, and store-data paths
- One-cycle load-use stalls
- PC and IF/ID freezing during hazards
- Bubble injection into ID/EX
- EX-stage branch/jump resolution
- Taken-branch and jump flushing
- Retirement interface for architectural verification

Directed tests cover back-to-back dependencies, load-use hazards, taken and not-taken branches, load-to-branch dependencies, store forwarding, JAL, and JALR.

---

# SoC Architecture

The processor is integrated into a custom memory-mapped SoC:

```text
                 +----------------+
                 |   RV32I Core   |
                 +-------+--------+
                         |
                  Memory-Mapped Bus
                         |
        +----------------+----------------+
        |                |                |
      DMEM             Timer            GPIO
                         |
                    Interrupts
                         |
                       UART
```

The SoC currently includes:

- RV32I CPU
- Instruction and data memories
- Modular memory-mapped bus
- GPIO peripheral
- UART interface
- Programmable machine timer
- Interrupt controller
- Machine-mode CSR subsystem

The CPU is kept independent of individual peripherals, allowing the SoC to be extended without modifying the processor datapath.

---

# Bare-Metal Runtime

Software executes directly on the custom processor without an operating system.

The runtime includes:

- `crt0` startup code
- `.bss` initialization
- Custom linker script
- Freestanding C support
- Stack and function-call support
- UART and timer drivers
- Machine-mode trap handling
- Periodic timer interrupts
- Context switching
- Preemptive round-robin scheduler

The scheduler has been validated on physical FPGA hardware using multiple independent tasks with persistent local state across repeated timer-driven context switches.

---

# FPGA Implementation

The SoC has been successfully deployed on a **Digilent Cora Z7-07S**, using the Zynq XC7Z007S programmable logic.

Hardware-validated functionality includes:

- RV32I program execution
- Compiled bare-metal C
- Memory-mapped GPIO controlling physical LEDs
- Machine timer interrupts
- Trap entry and return
- Preemptive context switching
- Multi-task scheduling
- UART output to a host computer

UART output is bridged from the custom RV32I processor in programmable logic through the Zynq Processing System:

```text
RV32I
  |
  | MMIO UART
  v
PL Mailbox
  |
  | synchronized VALID / ACK handshake
  v
AXI GPIO
  |
  v
Cortex-A9
  |
  v
PS UART0
  |
  v
Onboard USB-UART
  |
  v
Linux Host
```

The mailbox uses a synchronized multi-state handshake to safely transfer bytes between the programmable-logic and processing-system domains.

The FPGA design integrates:

- Custom SystemVerilog RTL
- Vivado IP Integrator
- Zynq Processing System
- AXI GPIO
- Clock/reset infrastructure
- Vitis bare-metal Cortex-A9 firmware
- XSDB/JTAG bring-up and debugging

---

# Verification

Verification is developed alongside the processor rather than added after implementation.

## Directed Verification

Current infrastructure includes:

- Self-checking SystemVerilog unit tests
- Full-SoC integration tests
- Assembly regression programs
- Compiled C regression programs
- FPGA hardware validation

Independently verified components include:

- ALU
- Register file
- Decoder
- Immediate generator
- Branch unit
- Instruction/data memory
- UART
- Timer
- Interrupt controller
- Memory-mapped bus
- CSR/trap subsystem
- Context switching and scheduler
- Pipeline forwarding and hazard logic
- Complete SoC

## Retirement-Based Verification

The pipelined processor exposes an architectural retirement interface:

```text
retire_valid
retire_pc
retire_instr
retire_reg_write
retire_rd
retire_rd_data
```

A reusable SystemVerilog monitor observes committed instructions independently of internal pipeline timing.

Optional retirement tracing allows failing programs to be reproduced and inspected instruction-by-instruction without generating verbose logs during normal regressions.

## Assertion-Based Verification

SystemVerilog assertions check pipeline invariants including:

- `x0` remains hardwired to zero
- Invalid pipeline entries cannot modify architectural state
- Memory transactions originate from valid instructions
- Load-use hazards stall the PC
- Load-use hazards inject pipeline bubbles
- Control-flow redirects flush younger instructions

## Randomized Differential Verification

A UVM-like randomized verification environment is under active development:

```text
                 Random Seed
                     |
                     v
            Instruction Generator
                 /         \
                v           v
       Generated RV32I   Python RV32I
          Assembly       Reference Model
                |           |
                v           |
          GNU Toolchain     |
                |           |
                v           |
          Verilator DUT     |
                |           |
                v           v
          RTL State ----> Scoreboard
                           |
                           v
                      PASS / FAIL
```

Current randomized verification supports:

- Reproducible seeded instruction generation
- Hundreds of randomized instructions per test
- Biased RAW dependencies to stress forwarding
- Independent Python architectural reference model
- Automatic comparison of all 32 architectural registers
- Multi-seed regression testing
- Optional retirement traces for failing seeds

Randomized ALU regressions currently exercise:

- ADD / SUB
- ADDI
- AND / OR / XOR
- SLL / SRL
- SLT / SLTU
- Back-to-back register dependencies

Randomized load/store and memory-state differential checking are currently being added.

---

# Software Build and Verification Flow

Programs are compiled with the GNU RISC-V toolchain using a custom linker script:

```text
C / Assembly
     |
     v
RISC-V GNU Toolchain
     |
     v
ELF
     |
     +----> IMEM image
     |
     +----> DMEM image
     |
     v
Simulation / FPGA
```

The Make-based flow supports normal programs, simulation, retirement tracing, and seeded randomized regressions.

Example:

```bash
make PROGRAM=test1 sim
```

Randomized differential test:

```bash
make random-sim SEED=1234 COUNT=500
```

Reproduce a failing seed with retirement tracing:

```bash
make random-sim SEED=1234 COUNT=500 TRACE_RETIRE=1
```

The same bare-metal software stack is used for RTL simulation and FPGA execution.

---

# Example FPGA Program

```c
#include "uart.h"

int main(void)
{
    uart_puts("Hello from RV32I FPGA!\n");

    while (1) {
    }
}
```

More advanced workloads exercise timer interrupts and multiple preemptively scheduled tasks on physical FPGA hardware.

---

# Roadmap

Current development direction:

- Complete randomized load/store and memory differential testing
- Add randomized branch/JAL/JALR verification
- Add functional coverage and automated multi-seed regressions
- Restore precise traps and asynchronous interrupts to the pipelined core
- Revalidate the pipelined processor on FPGA
- Convert instruction/data memory to a BRAM-friendly synchronous architecture
- Add hardware performance counters
- Implement AXI4-Lite-style SoC interconnect
- Build a DMA engine
- Integrate an INT8 systolic-array accelerator
- Run quantized ML workloads through the complete CPU/DMA/accelerator system
- Expand the UVM-like environment into a full UVM verification environment

---

# Technologies

- SystemVerilog
- RISC-V RV32I
- C / RISC-V Assembly
- Python
- Verilator
- GTKWave
- GNU RISC-V Toolchain
- Xilinx Vivado
- Vitis Embedded
- AXI / Zynq-7000
- XSDB / JTAG
- Make
- Git

---

# Repository Structure

```text
rtl/
    common/
    core/
    soc/
    fpga/

software/
    programs/
    runtime/

tests/
    unit/
    integration/
    uvm_like/
    random/

scripts/
docs/
```

---

# Project Goals

The project is designed to develop and demonstrate practical experience across:

- RTL and digital design
- CPU microarchitecture
- Pipeline hazard handling
- Design verification
- Assertion-based verification
- Constrained/randomized verification
- Architectural reference modeling
- FPGA implementation and bring-up
- RISC-V architecture
- SoC and memory-mapped interconnect design
- Embedded and bare-metal software
- Interrupt and context-switch architecture
- Clock-domain crossing
- Hardware/software co-design
- Accelerator architecture

The long-term goal is a **verified FPGA SoC combining a pipelined RISC-V processor, AXI-based interconnect, DMA subsystem, and systolic-array accelerator for quantized machine-learning workloads**.