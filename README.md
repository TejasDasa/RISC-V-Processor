# RV32I Processor and FPGA SoC

A custom RV32I processor and bare-metal SoC written from scratch in SystemVerilog, featuring a **five-stage pipelined CPU with precise traps and interrupts**, memory-mapped peripherals, preemptive multitasking, and deployment on a **Digilent Cora Z7-07S (Zynq-7000)** FPGA.

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
- Precise machine-mode exceptions and timer interrupts
- Harvard instruction/data memory architecture
- Fully synthesizable SystemVerilog

## Supported ISA

Supports the RV32I integer instruction set plus Zicsr and machine-mode
privileged instructions:

- Integer arithmetic and logical operations
- Immediate arithmetic and logic
- Shifts and signed/unsigned comparisons
- Byte, halfword, and word loads/stores
- Conditional branches
- JAL / JALR
- LUI / AUIPC
- CSRRW / CSRRS / CSRRC and the immediate forms CSRRWI / CSRRSI / CSRRCI
- ECALL / MRET
- Illegal-instruction exceptions, including access to unimplemented CSRs

Implemented CSRs: `mstatus` (MIE / MPIE writable, MPP reads as M-mode),
`mie`, `mip`, `mtvec` (direct mode), `mepc`, `mcause`, `mscratch`, and
`mtval` (reads as zero).

Not yet implemented: EBREAK, WFI, and misaligned-address exceptions.

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
- Precise exceptions and interrupts
- Retirement interface for architectural verification, including trap events

Directed tests cover back-to-back dependencies, load-use hazards, taken and not-taken branches, load-to-branch dependencies, store forwarding, JAL, and JALR.

## Precise Traps and Interrupts

EX is the single commit point for privileged side effects. Nothing in
MEM or WB can fault, so once an instruction leaves EX it is guaranteed
to retire. CSRs are read and written in EX, so back-to-back CSR
accesses need no stall.

When a trap is taken on the valid instruction in EX:

- older instructions in MEM and WB complete normally
- the trapping instruction is killed, with no register, CSR or memory
  side effects
- younger instructions in IF and ID are flushed
- `mepc` gets the trapping instruction's PC, `mcause` gets the cause,
  MPIE takes the value of MIE, and MIE is cleared
- the PC is redirected to `mtvec`

| Trap | `mcause` | `mepc` |
|------|----------|--------|
| Illegal instruction | 2 | the illegal instruction |
| ECALL | 11 | the ECALL (the handler adds 4) |
| Machine timer interrupt | `0x8000_0007` | the interrupted instruction, which re-executes after MRET |

The timer interrupt is taken only when `mstatus.MIE`, `mie.MTIE` and
`mip.MTIP` are all set, and only on a valid instruction. Bubbles have no
PC, so a pending interrupt waits for the next real instruction to reach
EX. MRET redirects to `mepc`, restores MIE from MPIE, and sets MPIE.

Redirect and stall priority:

```text
reset  >  trap / interrupt  >  MRET  >  JALR / JAL / taken branch  >  load-use stall
```

An interrupt therefore overrides a branch, a jump, an MRET, a load-use
stall, or even an exception on the same instruction; that instruction
simply runs again after the handler returns.

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

The scheduler was validated on physical FPGA hardware on the earlier single-cycle implementation, using multiple independent tasks with persistent local state across repeated timer-driven context switches. On the pipelined core it runs in simulation as a regression test (`sched_preempt`) and as a waveform demo.

---

# FPGA Implementation

The SoC has been successfully deployed on a **Digilent Cora Z7-07S**, using the Zynq XC7Z007S programmable logic.

Hardware validation so far was done with the earlier single-cycle CPU. The pipelined core is verified in simulation, and revalidating it on the FPGA is on the roadmap.

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

Directed privileged-mode programs on the pipelined core:

| Test | Checks |
|------|--------|
| `csr_hazards` | Back-to-back CSR writes/reads, CSR results forwarded at distances 1–3, load-use into a CSR source, `rs1 = x0` write suppression |
| `csr_ops` | CSRRC and the immediate forms, `mscratch`, `mtval`, `mstatus` WARL, illegal trap on unimplemented CSRs |
| `trap_sync` | ECALL and illegal instructions: older instructions complete, younger ones are flushed, no side effects, correct `mepc` / `mcause` |
| `mret_mpie` | MIE / MPIE stacking on trap entry and MRET, direct MRET to a chosen target |
| `irq_sweep` | The same block interrupted at every instruction position (load-use stalls, taken branches, JAL/JALR, CSR ops, stores); every run must match the uninterrupted checksum |
| `irq_repeat` | Enable gating (MIE, MTIE), re-taking a still-pending interrupt, no lost or duplicated instructions |
| `sched_preempt` | Preemptive two-task scheduler through the runtime trap path |

## Retirement-Based Verification

The pipelined processor exposes an architectural retirement interface:

```text
retire_valid
retire_pc
retire_instr
retire_reg_write
retire_rd
retire_rd_data

retire_exception
retire_interrupt
retire_cause
```

A reusable SystemVerilog monitor observes committed instructions independently of internal pipeline timing.

An instruction killed by a trap never asserts `retire_valid`. Instead it
appears as a trap event (`retire_exception` or `retire_interrupt`, with
`retire_cause`) at its program-order position: after every older
instruction and before the handler's first instruction.

Optional retirement tracing allows failing programs to be reproduced and inspected instruction-by-instruction without generating verbose logs during normal regressions.

## Assertion-Based Verification

SystemVerilog assertions check pipeline invariants including:

- `x0` remains hardwired to zero
- Invalid pipeline entries cannot modify architectural state
- Memory transactions originate from valid instructions
- Load-use hazards stall the PC unless a redirect overrides the stall
- Load-use hazards inject pipeline bubbles
- Control-flow redirects flush younger instructions
- Every redirect reaches the PC
- Traps redirect to `mtvec`, and MRET redirects to `mepc`
- Traps are taken only on valid instructions, and `mepc` captures that instruction's PC
- No younger instruction reaches MEM after a trap
- Interrupts are taken only when MIE, MTIE and MTIP are set, and an enabled, pending interrupt is never skipped
- The first retirement after a trap is the handler's first instruction, and the first retirement after MRET is at `mepc`

Assertions run in every simulation flow (`--assert`).

## Randomized Differential Verification

A UVM-like randomized differential verification environment compares
the RTL against an independent Python architectural model:

```text
                 Random Seed
                     |
                     v
            Instruction Generator
                     |
                     v
             Generated Assembly --------------+
                     |                        |
                     v                        |
               GNU Toolchain                  |
                     |                        |
                     v                        v
               Verilator DUT ---------->  Python RV32I
                     |       interrupt    Reference Model
                     |       positions        |
          retirement + trap trace       expected trace
                     |                        |
                     v                        v
                     +-----> Scoreboard <-----+
                                 |
                                 v
                            PASS / FAIL
```

Current randomized verification supports:

- Reproducible seeded instruction generation
- Hundreds of randomized instructions per test
- Biased RAW dependencies to stress forwarding
- Load-use pairs, word loads/stores, and memory-state comparison
- Taken and not-taken branches, JAL, and JAL/JALR helper calls with wrong-path victim instructions
- Retirement-by-retirement comparison (PC, destination register and value)
- Comparison of all 32 architectural registers and all modified memory
- Pipeline coverage counters (forwarding paths, stalls, redirects, loads/stores, traps, interrupts)
- Multi-seed regression with automatic failure logs

Randomized ALU regressions currently exercise:

- ADD / SUB
- ADDI
- AND / OR / XOR
- SLL / SRL
- SLT / SLTU
- Back-to-back register dependencies

Randomized privileged coverage:

- All six Zicsr forms (register and immediate), including `rs1 = x0` /
  `zimm = 0` write suppression and back-to-back CSR read-after-write
- ECALL and illegal instructions (bad encodings, unimplemented CSRs)
  through a generated trap handler
- Asynchronous timer interrupts with a per-seed schedule
- In-order comparison of every trap event (kind, PC, cause and
  position in the retirement stream)

Interrupt timing depends on RTL cycles, which the Python model does
not simulate. The flow therefore runs the RTL first. The model then
replays each interrupt at the retirement position where the RTL took
it, and rejects any interrupt that is not at the next architectural
PC or that arrives while `mstatus.MIE` / `mie.MTIE` is clear. The RTL
assertion `ap_irq_not_missed` covers the opposite case: a pending,
enabled interrupt that the RTL skipped.

A 50-seed run (300 generated instructions each) retires about 21,000
instructions and exercises about 370 exceptions and 175 interrupts.
The checker was mutation-tested: an ECALL `mepc` of PC+4, an interrupt
that skips its instruction, and immediate CSR forms reading the wrong
source are each caught.

## Waveform Demos

Seven short, self-checking programs produce focused waveforms of
individual pipeline behaviours on the real SoC: forwarding, the
load-use stall, branch flush, JAL/JALR call-return, store-data
forwarding, a precise timer interrupt with MRET, and a preemptive
two-task context switch. Each waveform shows per-stage disassembly
and forwarding-source signals, and comes with a GTKWave save file.

```bash
./scripts/run_all_waveforms.sh
gtkwave waves/02_load_use_stall.vcd tests/waveforms/gtkw/02_load_use_stall.gtkw
```

See [tests/waveforms/README.md](tests/waveforms/README.md) for what
each waveform shows and which signals to look at.

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

Randomized differential test (one seed, with retirement tracing):

```bash
make random-sim SEED=1234 COUNT=500
```

Regression entry points, run from the repository root:

```bash
./scripts/run_all_tests.sh                        # unit and SoC tests
./scripts/run_regression_tests.sh                 # directed program regression
python3 tests/random/run_regression.py --seeds 50 # randomized multi-seed regression
./scripts/run_all_waveforms.sh                    # waveform demos
```

A failing random seed saves its full log to
`tests/random/generated/failure_seed_<seed>.log`, and the regression
prints the `make random-sim` command that reproduces it.

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

Recently completed:

- Precise exceptions and timer interrupts on the pipelined core
- Full Zicsr support and illegal-instruction traps
- Randomized differential testing of CSRs, traps and interrupts
- Portfolio waveform demos

Current development direction:

- Revalidate the pipelined processor on FPGA
- Add EBREAK, WFI, and misaligned-address exceptions
- Randomize byte/halfword loads and stores
- Add SystemVerilog covergroups for functional coverage
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
    unit/          component testbenches
    integration/   SoC and program testbenches
    uvm_like/      monitor, assertions, coverage
    random/        generator, reference model, scoreboard
    waveforms/     portfolio waveform demos

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