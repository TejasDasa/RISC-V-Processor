# RV32I Processor and FPGA SoC

A custom RV32I processor and bare-metal SoC written from scratch in SystemVerilog, capable of executing compiled C, handling interrupts and preemptive multitasking, and running on a **Digilent Cora Z7-07S (Zynq-7000)** FPGA.

The project covers the full hardware/software stack: processor microarchitecture, RTL verification, memory-mapped peripherals, bare-metal runtime development, FPGA implementation, and hardware/software integration.

---

# Highlights

## Processor

- RV32I processor implemented from scratch in SystemVerilog
- Five-stage **IF / ID / EX / MEM / WB pipeline** *(in development)*
- EX/MEM and MEM/WB data forwarding
- Branch and store-data forwarding
- Harvard instruction/data memory architecture
- Machine-mode traps, interrupts, and CSRs
- Fully synthesizable RTL

## Supported ISA

Supports the RV32I integer instruction set, including:

- Integer arithmetic and logical operations
- Shifts and comparisons
- Byte, halfword, and word loads/stores
- Conditional branches
- JAL / JALR
- LUI / AUIPC
- CSR operations
- ECALL / MRET

---

# SoC Features

The custom SoC currently includes:

- RV32I CPU
- Instruction and data memories
- Modular memory-mapped bus
- GPIO peripheral
- UART interface
- Programmable timer
- Interrupt controller
- Machine-mode CSR subsystem

```text
                 +----------------+
                 |   RV32I Core   |
                 +-------+--------+
                         |
                  Memory-Mapped Bus
                         |
          +--------------+--------------+
          |              |              |
        DMEM           Timer          GPIO
                         |
                    Interrupts
                         |
                       UART
```

The CPU remains independent of individual peripherals, allowing the SoC to be extended without modifying the processor datapath.

---

# Bare-Metal Runtime

Software runs directly on the custom processor without an operating system.

The runtime includes:

- `crt0` startup code and `.bss` initialization
- Custom linker script
- Freestanding C support
- Stack and function-call support
- UART and timer drivers
- Machine-mode trap handling
- Periodic timer interrupts
- Context switching
- Preemptive round-robin scheduler

The scheduler has been validated on physical FPGA hardware using independent tasks with persistent local state across repeated timer-driven context switches.

---

# FPGA Implementation

The SoC has been deployed successfully on a **Digilent Cora Z7-07S**, using the Zynq XC7Z007S programmable logic.

Verified in hardware:

- RV32I program execution
- Memory-mapped GPIO controlling physical LEDs
- Timer interrupts
- Machine-mode trap entry/return
- Preemptive task scheduling
- UART output through the board's onboard USB interface

UART output is bridged between the custom RV32I SoC in programmable logic and the Zynq Processing System using an AXI GPIO mailbox with a synchronized valid/acknowledge handshake:

```text
RV32I
  |
  | MMIO UART
  v
PL Mailbox
  |
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
```

The design integrates custom RTL with Xilinx Vivado IP Integrator, AXI, Zynq PS initialization, and bare-metal Cortex-A9 firmware.

---

# Five-Stage Pipeline

Development is underway on a pipelined successor to the validated single-cycle core:

```text
 IF  ->  ID  ->  EX  ->  MEM  ->  WB
```

Currently implemented and verified:

- IF/ID, ID/EX, EX/MEM, and MEM/WB pipeline registers
- EX/MEM forwarding
- MEM/WB forwarding
- Branch operand forwarding
- Store-data forwarding
- Control-flow flushing

Current work focuses on load-use hazard detection and pipeline stalls before restoring precise interrupt/trap behavior to the pipelined design.

---

# Verification

Verification is performed continuously alongside RTL development.

Current infrastructure includes:

- Self-checking SystemVerilog unit tests
- Integration tests
- Assembly regression programs
- Compiled C regression programs
- Full-SoC simulation
- FPGA hardware validation

Verified components include:

- ALU
- Register file
- Decoder
- Immediate generator
- Branch unit
- Instruction/data memory
- UART
- Timer
- Interrupt controller
- Bus
- CSR/trap subsystem
- Context switching and scheduler
- Pipeline forwarding paths
- Complete SoC

---

# Software Build Flow

Programs are compiled with the GNU RISC-V toolchain and linked using a custom linker script.

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

The same bare-metal software stack is used for RTL simulation and FPGA execution.

---

# Example

```c
#include "uart.h"

int main(void)
{
    uart_puts("Hello from RV32I FPGA!\n");

    while (1) {
    }
}
```

More advanced programs exercise periodic timer interrupts and multiple preemptively scheduled tasks on the physical FPGA.

---

# Roadmap

Current development direction:

- Complete load-use hazard detection and pipeline stalls
- Restore precise traps and interrupts to the five-stage pipeline
- FPGA validation of the pipelined processor
- BRAM-friendly synchronous memory architecture
- Hardware performance counters
- Custom AXI4-Lite interconnect
- DMA engine
- INT8 systolic-array accelerator
- Quantized ML inference workloads
- Expanded assertion-based and constrained-random verification
- UVM verification environment

---

# Technologies

- SystemVerilog
- RISC-V RV32I
- C / RISC-V Assembly
- Verilator
- GTKWave
- GNU RISC-V Toolchain
- Xilinx Vivado
- Vitis Embedded
- AXI / Zynq-7000
- XSDB / JTAG
- Make
- Git
- Python

---

# Repository Structure

```text
rtl/
    common/
    core/
    soc/
    fpga/

runtime/

software/
    programs/

tests/
    unit/
    integration/

scripts/
docs/
```

---

# Project Goals

The project is designed to develop and demonstrate practical experience in:

- RTL and digital design
- CPU microarchitecture
- Design verification
- FPGA implementation
- RISC-V architecture
- SoC and memory-mapped interconnect design
- Embedded and bare-metal software
- Interrupt and context-switch architecture
- Hardware/software co-design
- Accelerator architecture

The long-term goal is a verified FPGA SoC combining a pipelined RISC-V processor, AXI-based interconnect, DMA subsystem, and hardware accelerator for quantized machine-learning workloads.