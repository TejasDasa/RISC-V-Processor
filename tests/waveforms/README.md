# Waveform demos

Seven short, deterministic programs. Each one runs on the real SoC
(`soc` → `core`, unchanged RTL) and isolates one pipeline behaviour.
Each run stops a few cycles after the interesting event and dumps
only a curated probe scope, so the waveform shows what matters and
nothing else.

| # | Demo | Cycles | Shows |
|---|------|-------:|-------|
| 01 | `01_forwarding_chain` | 16 | Back-to-back RAW hazards resolved by EX/MEM and MEM/WB forwarding |
| 02 | `02_load_use_stall` | 16 | One-cycle load-use stall and bubble |
| 03 | `03_branch_flush` | 18 | Taken branch in EX squashing two wrong-path instructions |
| 04 | `04_jal_jalr_call` | 19 | Function call and return with JAL / JALR |
| 05 | `05_store_forwarding` | 18 | Forwarded store data, byte-lane alignment on the bus |
| 06 | `06_timer_interrupt` | 45 | Precise timer interrupt, trap entry, MRET |
| 07 | `07_sched_preempt` | ~715 dumped | Preemptive two-task context switch |

## Running

The toolchain (Verilator 5, `riscv64-unknown-elf-gcc`, Python 3) is
the same as the regression flow. From the repository root:

```bash
./scripts/run_waveform.sh 01_forwarding_chain   # one demo
./scripts/run_all_waveforms.sh                  # all demos + .gtkw files
```

Each demo writes:

| File | Contents |
|------|----------|
| `waves/<demo>.vcd` | waveform (probe signals only) |
| `logs/<demo>.wave.log` | per-cycle `PIPE` table + register dump |

Open one in GTKWave with its signals pre-arranged:

```bash
gtkwave waves/03_branch_flush.vcd tests/waveforms/gtkw/03_branch_flush.gtkw
```

For compressed FST instead of VCD, install the zlib headers
(`sudo apt install zlib1g-dev`) and run with `WAVE_FORMAT=fst`.

Every demo is also a self-checking test: the final register file is
compared against `programs/<demo>.expected`, and the pipeline
assertions from `tests/uvm_like/cpu_assertions.sv` run throughout.

## How the probe works

`wave_probe.sv` is the only traced scope (`waves.vlt` switches
tracing off for `rtl/` and the checkers). It keeps the core's own
signal names (`id_ex_rs1_addr`, `ex_rs1_forwarded`,
`load_use_hazard`, ...) and adds a few derived signals for
readability:

| Signal | Meaning |
|--------|---------|
| `cycle` | cycles since reset release (matches the `PIPE` log) |
| `if_asm` … `wb_asm` | disassembled instruction in each stage, `bubble` when the stage is invalid, `TRAP ...` for an instruction killed by a trap. Set GTKWave *Data Format → ASCII* (the `.gtkw` files already do). |
| `fwd_rs1_src`, `fwd_rs2_src` | where EX's operands came from: `EX/MEM`, `MEM/WB` or `regfile` |
| `x1_ra`, `x2_sp`, `x10_a0` | selected architectural registers |

Cycle numbers below refer to the `cycle` signal. The exact
cycle-by-cycle pipeline for each demo is in the comment block at the
top of its program under `programs/`.

---

## 01 · Forwarding chain

```asm
addi x1, x0, 5
addi x2, x1, 3      # x1 from EX/MEM
add  x3, x2, x1     # x2 from EX/MEM, x1 from MEM/WB
sub  x4, x3, x2     # x3 from EX/MEM, x2 from MEM/WB
```

**Demonstrates:** every instruction depends on the one or two before
it, and the pipeline never stalls.

**Signals:** `ex_asm`, `id_ex_rs1_addr`, `id_ex_rs2_addr`,
`ex_mem_rd_addr`, `mem_wb_rd_addr`, `fwd_rs1_src`, `fwd_rs2_src`,
`id_ex_rs1_data`, `ex_rs1_forwarded`, `ex_rs2_forwarded`,
`ex_alu_result`, `wb_reg_write_en`, `wb_rd_addr`, `wb_data`.

**What to notice:**
- Cycles 3–5: `id_ex_rs1_addr` equals `ex_mem_rd_addr`, so
  `fwd_rs1_src = EX/MEM`. In cycles 4–5 `id_ex_rs2_addr` also equals
  `mem_wb_rd_addr`, so `fwd_rs2_src = MEM/WB`.
- `id_ex_rs1_data` (the stale register-file value) is 0 while
  `ex_rs1_forwarded` carries the correct value (5, 8, 13).
- `load_use_hazard` stays 0: four dependent instructions in four
  consecutive cycles.

**Caption:** *Four back-to-back dependent instructions flow through
the pipeline with zero stalls, with operands forwarded from both
EX/MEM and MEM/WB in the same cycle.*

---

## 02 · Load-use stall

```asm
lui  x1, 0x10
lw   x3, 0(x1)      # x3 = 34
addi x4, x3, 8      # needs x3 before memory has returned it
```

**Demonstrates:** the one case forwarding cannot cover. Load data only
exists at the end of MEM, so the dependent instruction waits exactly
one cycle.

**Signals:** `load_use_hazard`, `pc_we`, `pc_current`, `if_id_pc`,
`if_id_instr`, `id_ex_valid`, `id_ex_mem_read_en`, `id_ex_rd_addr`,
`ex_mem_valid`, `mem_wb_valid`, `fwd_rs1_src`, `ex_rs1_forwarded`,
`wb_data`.

**What to notice:**
- Cycle 3: `lw` in EX (`id_ex_mem_read_en = 1`, `id_ex_rd_addr = 3`)
  with `addi x4,x3,8` in ID → `load_use_hazard = 1` and `pc_we = 0`.
- Cycle 4: `pc_current` (0x0c) and `if_id_pc` (0x08) have not
  advanced, and `id_ex_valid = 0`: a bubble enters EX
  (`ex_asm = bubble`).
- Cycle 5: `addi` reaches EX with `fwd_rs1_src = MEM/WB` and
  `ex_rs1_forwarded = 0x22`, the load data on `wb_data` that same
  cycle.

**Caption:** *A load followed by a dependent instruction costs exactly
one cycle: the hazard unit freezes the PC and IF/ID, injects a single
bubble, and the loaded value is forwarded from MEM/WB.*

---

## 03 · Taken branch flush

```asm
addi x1, x0, 5
addi x2, x0, 5
beq  x1, x2, target     # taken
addi x3, x0, 99         # wrong path
addi x4, x0, 99         # wrong path
target:
addi x5, x0, 7
```

**Demonstrates:** control-hazard recovery. The branch resolves in EX
after two sequential instructions have already been fetched.

**Signals:** `ex_rs1_forwarded`, `ex_rs2_forwarded`, `fwd_rs1_src`,
`fwd_rs2_src`, `ex_branch_taken`, `ex_take_branch`, `ex_redirect`,
`ex_redirect_pc`, `pc_current`, `if_id_valid`, `id_ex_valid`, stage
`*_asm`.

**What to notice:**
- Cycle 4: `beq` in EX with both operands = 5 (x1 via MEM/WB, x2 via
  EX/MEM); `ex_branch_taken`, `ex_take_branch` and `ex_redirect` all
  pulse, and `ex_redirect_pc = 0x14`.
- At the same moment `id_asm = addi x3,x0,99` and
  `if_asm = addi x4,x0,99`.
- Cycle 5: `pc_current = 0x14`, `if_id_valid = 0`, `id_ex_valid = 0`.
  Both wrong-path instructions are gone and never reach `wb_asm`;
  x3 and x4 stay 0.
- `addi x5,x0,7` is fetched in cycle 5 and reaches EX in cycle 7:
  a two-cycle branch penalty.

**Caption:** *A taken branch resolved in EX redirects fetch and squashes
the two wrong-path instructions already in flight, so neither ever
writes a register.*

---

## 04 · JAL / JALR call and return

```asm
0x00  addi a0, x0, 20
0x04  jal  ra, func       # ra = 0x08
0x08  addi a1, a0, 1      # return point
0x0c  j .
func:
0x10  add  a0, a0, a0
0x14  addi a0, a0, 2
0x18  jalr x0, 0(ra)
```

**Demonstrates:** a complete call/return round trip, with the link
register written through the normal pipeline and consumed by JALR.

**Signals:** `ex_take_jump`, `ex_take_jalr`, `ex_redirect`,
`ex_redirect_pc`, `pc_current`, `ex_rs1_forwarded`, `x1_ra`,
`x10_a0`, `wb_rd_addr`, `wb_data`.

**What to notice:**
- Cycle 3: `ex_take_jump = 1`, `ex_redirect_pc = 0x10`, and the fall-
  through `addi a1` in ID is squashed.
- Cycle 5: the JAL retires with `wb_rd_addr = 1`, `wb_data = 0x08`
  (PC+4). `x1_ra` becomes 0x08.
- Cycle 8: `ex_take_jalr = 1` with `ex_rs1_forwarded = 0x08`, so
  `ex_redirect_pc = 0x08`.
- Cycle 11: execution continues at the return point; a0 = 42,
  a1 = 43.

**Caption:** *A function call and return on the pipelined core: JAL
links PC+4 into ra and redirects to the callee, and JALR returns to
exactly the instruction after the call.*

---

## 05 · Store-data forwarding

```asm
addi x1, x0, 42
lui  x2, 0x10
sw   x1, 0(x2)      # base from EX/MEM, data from MEM/WB
sb   x1, 5(x2)      # byte lane 1
lw   x3, 0(x2)      # 42
lw   x4, 4(x2)      # 0x2a00
```

**Demonstrates:** stores need two forwarded operands, the address
base (rs1) and the data (rs2), and the MEM stage aligns the data to
the right byte lane.

**Signals:** `fwd_rs1_src`, `fwd_rs2_src`, `ex_rs1_forwarded`,
`ex_rs2_forwarded`, `ex_alu_result`, `ex_mem_rs2_data`, `bus_addr`,
`bus_write_en`, `bus_write_data`, `bus_byte_en`, `bus_read_data`.

**What to notice:**
- Cycle 4: `sw` in EX with `fwd_rs1_src = EX/MEM` (0x10000) and
  `fwd_rs2_src = MEM/WB` (42): both of its operands are still in the
  pipeline.
- Cycle 5: `ex_mem_rs2_data = 0x2a`, `bus_write_en = 1`,
  `bus_addr = 0x10000`, `bus_write_data = 0x0000002a`,
  `bus_byte_en = 1111`.
- Cycle 6: the `sb` drives `bus_addr = 0x10005`,
  `bus_write_data = 0x00002a00`, `bus_byte_en = 0010`.
- The two loads read the values back (x3 = 42, x4 = 0x2a00).
  `bus_byte_en` only matters while `bus_write_en = 1`.

**Caption:** *A store whose base address and data are both still in
flight gets them from two different forwarding paths, then drives the
bus with correctly aligned data and byte enables.*

---

## 06 · Timer interrupt → trap entry → MRET

The program arms the machine timer, enables `mie.MTIE` and
`mstatus.MIE`, then runs a sled of eight `addi x10, x10, 1`. The
interrupt lands on the fourth one.

**Demonstrates:** a precise asynchronous interrupt.
- Older instructions complete.
- The interrupted instruction is killed and becomes `mepc`.
- Younger instructions are flushed.
- MRET resumes at exactly that instruction.

**Signals:** `timer_count`, `timer_compare`, `cpu_irq`,
`timer_irq_pending`, `global_irq_enable` (mstatus.MIE),
`timer_irq_enable` (mie.MTIE), `mstatus`, `ex_irq`, `trap_enter`,
`trap_cause`, `ex_redirect_pc`, `mtvec`, `mepc`, `mcause`,
`ex_take_mret`, `if_id_valid`, `id_ex_valid`, `retire_interrupt`,
`x10_a0` (holds x10).

**What to notice:**
- Cycle 22: `timer_count` reaches `timer_compare` and `cpu_irq`
  rises. With MIE = MTIE = 1, `ex_irq` and `trap_enter` fire on the
  sled instruction in EX, and `ex_redirect_pc = mtvec = 0x68`.
- Cycle 23: `mepc = 0x4c`, `mcause = 0x80000007`,
  `global_irq_enable` drops to 0. `mem_asm = TRAP addi x10,x10,1`:
  the killed instruction continues down the pipe with no side
  effects, and `retire_interrupt` pulses for it in cycle 24.
- The two sled instructions ahead of it still write back
  (x10 = 2, 3). The two behind it are squashed.
- Cycle 29: `ex_take_mret = 1`, `ex_redirect_pc = mepc = 0x4c`.
  From cycle 30 `global_irq_enable` is 1 again (MIE ← MPIE). The
  killed `addi` executes again, and x10 finishes at exactly 8.
- Earlier, `cpu_irq` is 0 even though the timer is enabled (compare
  = max); the handler also pushes compare back to max so the
  interrupt is not re-taken.

**Caption:** *A timer interrupt taken precisely mid-stream: older
instructions retire, the interrupted one becomes mepc, younger ones
are flushed, and MRET resumes so that no instruction is lost or run
twice.*

---

## 07 · Preemptive two-task context switch

Task A loops writing `0xA` to GPIO; task B loops writing `0xB`. The
timer interrupt drives the full runtime path:
- `trap_entry` saves 29 registers and `mepc` on the current task's
  stack.
- `trap_handler` calls `scheduler_tick`, which returns the other
  task's stack pointer.
- `trap_entry` restores that task's registers and `mepc`, then MRET
  resumes it.

The dump starts at the first MRET, skipping C startup.

**Demonstrates:** the preemptive scheduler from the single-cycle
design, now running on the pipelined core with precise interrupts.

**Signals:** `gpio_out` (the current task), `x2_sp`, `pc_current`,
`ex_asm`, `timer_count`, `timer_compare`, `cpu_irq`, `ex_irq`,
`trap_enter`, `mepc`, `mcause`, `ex_take_mret`, `ex_redirect_pc`,
`bus_write_en`, `bus_read_en`, `bus_addr`, `bus_write_data`,
`bus_read_data`.

**What to notice:**

| Cycle | Event |
|------:|-------|
| 1396 | MRET from `context_start_preemptive` enters task A |
| 1408 | `gpio_out = 0xA`, `x2_sp = 0x10170` (A's stack) |
| 1480 | Tick: `trap_enter`, then a burst of `bus_write_en` saves A's context (trap_entry's 30 saves plus the C handler's stack frame) |
| 1697 | After a `bus_read_en` burst restores B's registers and `mepc`, MRET → `mepc = 0x94` (`task_b`) |
| 1750 | `gpio_out = 0xB`, `x2_sp = 0x102f0` (B's stack) |
| 1864 | Tick: B preempted, B's context saved |
| 2080 | MRET → `mepc = 0x78`, the exact `beqz` A was preempted on at 1480 |
| 2091 | `gpio_out = 0xA`; A sees B made progress and halts |

**Caption:** *Timer-driven preemptive multitasking on the pipelined
core: each tick saves one task's registers, switches stacks, and
resumes the other task at the exact instruction where it was
interrupted.*

---

## Files

```
tests/waveforms/
  wave_tb.sv          testbench: soc + probe + assertions, run control
  wave_probe.sv       traced scope: core signals + derived signals
  rv_disasm_pkg.sv    RV32I/Zicsr disassembler for the *_asm signals
  waves.vlt           Verilator config: trace the probe only
  programs/           demo programs, .expected results, .flags
  gtkw/               GTKWave save files (generated by gen_gtkw.py)
  gen_gtkw.py         regenerates gtkw/ from the signal lists
  vcd_peek.py         prints signals per cycle from a VCD (no GUI)
scripts/
  run_waveform.sh     build + run one demo
  run_all_waveforms.sh
```

To check a waveform without GTKWave:

```bash
python3 tests/waveforms/vcd_peek.py waves/02_load_use_stall.vcd \
    cycle ex_asm load_use_hazard pc_current id_ex_valid fwd_rs1_src
```
