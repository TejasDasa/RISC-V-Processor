#!/usr/bin/env python3

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
import re
import sys


U32_MASK = 0xFFFF_FFFF

MEM_PATTERN = re.compile(
    r"([-+]?(?:0[xX][0-9A-Fa-f]+|\d+))"
    r"\(x(\d+)\)"
)

# Retirement / trap lines printed by the RTL (cpu_monitor, TRACE_RETIRE)
RTL_RETIRE_PATTERN = re.compile(r"^RETIRE\s+pc=")
RTL_TRAP_PATTERN = re.compile(
    r"TRAP_EVENT\s+kind=(\w+)\s+pc=([0-9a-fA-F]+)\s+"
    r"instr=[0-9a-fA-F]+\s+cause=([0-9a-fA-F]+)"
)

# Device registers (timer, UART, GPIO). Stores there are not part of
# the architectural memory image compared against the RTL.
MMIO_BASE = 0x1000_0000

# ------------------------------------------------------------
# Machine-mode CSRs (matches rtl/core/csr_file.sv)
# ------------------------------------------------------------

CSR_MSTATUS = 0x300
CSR_MIE = 0x304
CSR_MTVEC = 0x305
CSR_MSCRATCH = 0x340
CSR_MEPC = 0x341
CSR_MCAUSE = 0x342
CSR_MTVAL = 0x343
CSR_MIP = 0x344

CSR_NAMES = {
    "mstatus": CSR_MSTATUS,
    "mie": CSR_MIE,
    "mtvec": CSR_MTVEC,
    "mscratch": CSR_MSCRATCH,
    "mepc": CSR_MEPC,
    "mcause": CSR_MCAUSE,
    "mtval": CSR_MTVAL,
    "mip": CSR_MIP,
}

CSR_IMPLEMENTED = set(CSR_NAMES.values())

MSTATUS_MIE = 1 << 3
MSTATUS_MPIE = 1 << 7
MSTATUS_WMASK = MSTATUS_MIE | MSTATUS_MPIE
MSTATUS_MPP_M = 0x1800
MIE_MTIE = 1 << 7

CAUSE_ILLEGAL = 0x0000_0002
CAUSE_ECALL = 0x0000_000B
CAUSE_TIMER_IRQ = 0x8000_0007

CSR_OPS = {"csrrw", "csrrs", "csrrc", "csrrwi", "csrrsi", "csrrci"}


class ModelError(Exception):
    """The RTL trace asked for something architecturally illegal."""


def u32(value: int) -> int:
    return value & U32_MASK


def s32(value: int) -> int:
    value = u32(value)

    if value & 0x8000_0000:
        return value - 0x1_0000_0000

    return value


def parse_reg(token: str) -> int:
    match = re.fullmatch(
        r"x(\d+)",
        token.strip(),
    )

    if match is None:
        raise ValueError(
            f"Invalid register: {token}"
        )

    reg = int(match.group(1))

    if not 0 <= reg <= 31:
        raise ValueError(
            f"Register out of range: x{reg}"
        )

    return reg


def parse_imm(token: str) -> int:
    return int(token.strip(), 0)


def parse_mem_operand(
    token: str,
) -> tuple[int, int]:

    match = MEM_PATTERN.fullmatch(
        token.strip()
    )

    if match is None:
        raise ValueError(
            f"Invalid memory operand: {token}"
        )

    offset = int(
        match.group(1),
        0,
    )

    reg = int(
        match.group(2)
    )

    return offset, reg


@dataclass
class Instruction:
    pc: int
    text: str


def parse_csr(token: str) -> int:
    token = token.strip().lower()

    if token in CSR_NAMES:
        return CSR_NAMES[token]

    return int(token, 0)


@dataclass
class RetireEvent:
    pc: int
    reg_write: bool
    rd: int
    data: int


@dataclass
class TrapEvent:
    kind: str       # "exception" or "interrupt"
    pc: int         # trapped instruction (= mepc)
    cause: int
    after: int      # number of retirements before this trap


@dataclass
class Injection:
    pc: int
    after: int


def load_rtl_interrupts(path: Path) -> list[Injection]:
    """
    Interrupt positions from the RTL simulation log.

    Asynchronous interrupt timing depends on RTL cycles, which this
    model does not simulate. Instead, each interrupt the RTL took is
    replayed at the same position in the retirement stream (after
    the same number of retired instructions). The model checks that
    the position is a legal one: the PC must match and interrupts
    must be enabled there.
    """

    injections: list[Injection] = []
    retired = 0

    for line in path.read_text().splitlines():
        if RTL_RETIRE_PATTERN.search(line):
            retired += 1
            continue

        match = RTL_TRAP_PATTERN.search(line)

        if match and match.group(1) == "interrupt":
            injections.append(
                Injection(
                    pc=int(match.group(2), 16),
                    after=retired,
                )
            )

    return injections


class RV32IReferenceModel:
    def __init__(self) -> None:
        self.regs = [0] * 32

        self.memory: dict[int, int] = {}

        self.instructions: dict[
            int,
            Instruction
        ] = {}

        self.labels: dict[str, int] = {}

        self.retire_events: list[
            RetireEvent
        ] = []

        self.pc = 0

        self.halt_pc: int | None = None

        # Machine-mode CSR state (mstatus holds only MIE / MPIE).
        self.csrs: dict[int, int] = {
            CSR_MSTATUS: 0,
            CSR_MIE: 0,
            CSR_MTVEC: 0,
            CSR_MSCRATCH: 0,
            CSR_MEPC: 0,
            CSR_MCAUSE: 0,
        }

        self.trap_events: list[TrapEvent] = []

        # Interrupts to replay, from the RTL trace (see
        # load_rtl_interrupts).
        self.injections: list[Injection] = []

    # ============================================================
    # Architectural state
    # ============================================================

    def read_reg(
        self,
        reg: int,
    ) -> int:

        if reg == 0:
            return 0

        return self.regs[reg]

    def write_reg(
        self,
        reg: int,
        value: int,
    ) -> None:

        if reg == 0:
            return

        self.regs[reg] = u32(value)

    def load_word(
        self,
        addr: int,
    ) -> int:

        return self.memory.get(
            u32(addr),
            0,
        )

    def store_word(
        self,
        addr: int,
        value: int,
    ) -> None:

        # Device register writes (timer compare/control) are not
        # part of the compared memory image.
        if u32(addr) >= MMIO_BASE:
            return

        self.memory[u32(addr)] = u32(
            value
        )

    # ============================================================
    # CSRs and traps
    # ============================================================

    def csr_read(self, addr: int) -> int:
        if addr == CSR_MSTATUS:
            return self.csrs[CSR_MSTATUS] | MSTATUS_MPP_M

        if addr == CSR_MTVAL:
            return 0

        if addr == CSR_MIP:
            raise ModelError(
                "mip reads depend on timer cycles and are not "
                "modeled; the generator must not emit them"
            )

        return self.csrs[addr]

    def csr_write(self, addr: int, value: int) -> None:
        value = u32(value)

        if addr == CSR_MSTATUS:
            self.csrs[CSR_MSTATUS] = value & MSTATUS_WMASK

        elif addr in (CSR_MTVAL, CSR_MIP):
            pass    # read-only / hardware-driven

        else:
            self.csrs[addr] = value

    def take_trap(self, pc: int, cause: int) -> int:
        """Trap entry. Returns the handler PC (mtvec)."""

        status = self.csrs[CSR_MSTATUS]
        mpie = MSTATUS_MPIE if (status & MSTATUS_MIE) else 0

        self.csrs[CSR_MSTATUS] = mpie               # MIE = 0
        self.csrs[CSR_MEPC] = u32(pc)
        self.csrs[CSR_MCAUSE] = u32(cause)

        self.trap_events.append(
            TrapEvent(
                kind=(
                    "interrupt"
                    if cause & 0x8000_0000
                    else "exception"
                ),
                pc=u32(pc),
                cause=u32(cause),
                after=len(self.retire_events),
            )
        )

        return self.csrs[CSR_MTVEC]

    def take_injected_interrupts(self) -> None:
        """Take every RTL interrupt due at this retirement count."""

        retired = len(self.retire_events)

        while self.injections:
            injection = self.injections[0]

            if injection.after > retired:
                return

            if injection.after < retired:
                raise ModelError(
                    f"RTL took an interrupt after retirement "
                    f"#{injection.after} (pc=0x{injection.pc:08x}), "
                    f"but the model passed that point without a "
                    f"legal interrupt boundary"
                )

            self.injections.pop(0)

            if injection.pc != self.pc:
                raise ModelError(
                    f"RTL interrupted pc=0x{injection.pc:08x} after "
                    f"retirement #{retired}, but the next "
                    f"architectural instruction is "
                    f"pc=0x{self.pc:08x}"
                )

            mie_on = self.csrs[CSR_MSTATUS] & MSTATUS_MIE
            mtie_on = self.csrs[CSR_MIE] & MIE_MTIE

            if not (mie_on and mtie_on):
                raise ModelError(
                    f"RTL took an interrupt at pc=0x{self.pc:08x} "
                    f"while it was disabled "
                    f"(mstatus.MIE={int(bool(mie_on))}, "
                    f"mie.MTIE={int(bool(mtie_on))})"
                )

            self.pc = self.take_trap(self.pc, CAUSE_TIMER_IRQ)

    # ============================================================
    # Assembly loading
    # ============================================================

    def load_program(
        self,
        path: Path,
    ) -> None:

        pc = 0

        # --------------------------------------------------------
        # Pass 1: collect labels
        # --------------------------------------------------------

        for raw_line in path.read_text().splitlines():
            line = raw_line.split(
                "#",
                1,
            )[0].strip()

            if not line:
                continue

            # ".word" emits an instruction word; other directives
            # take no space in .text.
            if line.startswith(".") and not line.startswith(".word"):
                continue

            if line.endswith(":"):
                label = line[:-1].strip()

                self.labels[label] = pc
                continue

            pc += 4

        # --------------------------------------------------------
        # Pass 2: collect instructions
        # --------------------------------------------------------

        pc = 0

        for raw_line in path.read_text().splitlines():
            line = raw_line.split(
                "#",
                1,
            )[0].strip()

            if not line:
                continue

            if line.startswith(".") and not line.startswith(".word"):
                continue

            if line.endswith(":"):
                continue

            self.instructions[pc] = (
                Instruction(
                    pc=pc,
                    text=line,
                )
            )

            pc += 4

        if "_start" in self.labels:
            self.pc = self.labels["_start"]
        else:
            self.pc = 0

        self.halt_pc = self.labels.get(
            "halt"
        )

    # ============================================================
    # Retirement bookkeeping
    # ============================================================

    def retire(
        self,
        pc: int,
        reg_write: bool = False,
        rd: int = 0,
        data: int = 0,
    ) -> None:

        self.retire_events.append(
            RetireEvent(
                pc=u32(pc),
                reg_write=reg_write,
                rd=rd,
                data=u32(data),
            )
        )

    # ============================================================
    # Execute one instruction
    # ============================================================

    def step(self) -> None:
        if self.pc not in self.instructions:
            raise RuntimeError(
                f"No instruction at "
                f"PC 0x{self.pc:08x}"
            )

        current_pc = self.pc

        instr = self.instructions[
            current_pc
        ]

        tokens = (
            instr.text
            .replace(",", " ")
            .split()
        )

        op = tokens[0].lower()

        # Default next PC.
        next_pc = u32(
            current_pc + 4
        )

        # --------------------------------------------------------
        # ADDI
        # --------------------------------------------------------

        if op == "addi":
            rd = parse_reg(tokens[1])
            rs1 = parse_reg(tokens[2])
            imm = parse_imm(tokens[3])

            result = u32(
                self.read_reg(rs1)
                + imm
            )

            self.write_reg(
                rd,
                result,
            )

            self.retire(
                current_pc,
                reg_write=(rd != 0),
                rd=rd,
                data=result,
            )

        # --------------------------------------------------------
        # LUI
        # --------------------------------------------------------

        elif op == "lui":
            rd = parse_reg(tokens[1])
            imm = parse_imm(tokens[2])

            result = u32(
                imm << 12
            )

            self.write_reg(
                rd,
                result,
            )

            self.retire(
                current_pc,
                reg_write=(rd != 0),
                rd=rd,
                data=result,
            )

        # --------------------------------------------------------
        # Register-register ALU
        # --------------------------------------------------------

        elif op in {
            "add",
            "sub",
            "and",
            "or",
            "xor",
            "sll",
            "srl",
            "slt",
            "sltu",
        }:
            rd = parse_reg(tokens[1])
            rs1 = parse_reg(tokens[2])
            rs2 = parse_reg(tokens[3])

            a = self.read_reg(rs1)
            b = self.read_reg(rs2)

            if op == "add":
                result = a + b

            elif op == "sub":
                result = a - b

            elif op == "and":
                result = a & b

            elif op == "or":
                result = a | b

            elif op == "xor":
                result = a ^ b

            elif op == "sll":
                result = (
                    a << (b & 0x1F)
                )

            elif op == "srl":
                result = (
                    u32(a)
                    >> (b & 0x1F)
                )

            elif op == "slt":
                result = int(
                    s32(a) < s32(b)
                )

            elif op == "sltu":
                result = int(
                    u32(a) < u32(b)
                )

            else:
                raise AssertionError(
                    "unreachable"
                )

            result = u32(result)

            self.write_reg(
                rd,
                result,
            )

            self.retire(
                current_pc,
                reg_write=(rd != 0),
                rd=rd,
                data=result,
            )

        # --------------------------------------------------------
        # LW
        # --------------------------------------------------------

        elif op == "lw":
            rd = parse_reg(tokens[1])

            offset, rs1 = parse_mem_operand(
                tokens[2]
            )

            addr = u32(
                self.read_reg(rs1)
                + offset
            )

            result = self.load_word(
                addr
            )

            self.write_reg(
                rd,
                result,
            )

            self.retire(
                current_pc,
                reg_write=(rd != 0),
                rd=rd,
                data=result,
            )

        # --------------------------------------------------------
        # SW
        # --------------------------------------------------------

        elif op == "sw":
            rs2 = parse_reg(tokens[1])

            offset, rs1 = parse_mem_operand(
                tokens[2]
            )

            addr = u32(
                self.read_reg(rs1)
                + offset
            )

            self.store_word(
                addr,
                self.read_reg(rs2),
            )

            self.retire(
                current_pc
            )

        # --------------------------------------------------------
        # Conditional branches
        # --------------------------------------------------------

        elif op in {
            "beq",
            "bne",
            "blt",
            "bge",
            "bltu",
            "bgeu",
        }:
            rs1 = parse_reg(tokens[1])
            rs2 = parse_reg(tokens[2])
            label = tokens[3]

            a = self.read_reg(rs1)
            b = self.read_reg(rs2)

            if op == "beq":
                taken = a == b

            elif op == "bne":
                taken = a != b

            elif op == "blt":
                taken = (
                    s32(a) < s32(b)
                )

            elif op == "bge":
                taken = (
                    s32(a) >= s32(b)
                )

            elif op == "bltu":
                taken = (
                    u32(a) < u32(b)
                )

            elif op == "bgeu":
                taken = (
                    u32(a) >= u32(b)
                )

            else:
                raise AssertionError(
                    "unreachable"
                )

            if taken:
                next_pc = self.labels[
                    label
                ]

            self.retire(
                current_pc
            )

        # --------------------------------------------------------
        # JAL
        # --------------------------------------------------------

        elif op == "jal":
            rd = parse_reg(tokens[1])
            label = tokens[2]

            link = u32(
                current_pc + 4
            )

            self.write_reg(
                rd,
                link,
            )

            next_pc = self.labels[
                label
            ]

            self.retire(
                current_pc,
                reg_write=(rd != 0),
                rd=rd,
                data=link,
            )

        # --------------------------------------------------------
        # JALR
        # --------------------------------------------------------

        elif op == "jalr":
            rd = parse_reg(tokens[1])

            offset, rs1 = parse_mem_operand(
                tokens[2]
            )

            link = u32(
                current_pc + 4
            )

            target = u32(
                self.read_reg(rs1)
                + offset
            )

            target &= 0xFFFF_FFFE

            self.write_reg(
                rd,
                link,
            )

            next_pc = target

            self.retire(
                current_pc,
                reg_write=(rd != 0),
                rd=rd,
                data=link,
            )

        # --------------------------------------------------------
        # Zicsr: CSRRW / CSRRS / CSRRC and immediate forms
        # --------------------------------------------------------

        elif op in CSR_OPS:
            rd = parse_reg(tokens[1])
            addr = parse_csr(tokens[2])

            # Immediate forms use zimm; the rs1 field is either the
            # register number or zimm, and it gates the write for
            # the set / clear forms.
            if op.endswith("i"):
                field = parse_imm(tokens[3]) & 0x1F
                src = field
            else:
                field = parse_reg(tokens[3])
                src = self.read_reg(field)

            if addr not in CSR_IMPLEMENTED:
                # Unimplemented CSR: illegal instruction, no effect.
                next_pc = self.take_trap(current_pc, CAUSE_ILLEGAL)

            else:
                old = self.csr_read(addr)
                base = op.rstrip("i")

                if base == "csrrw":
                    self.csr_write(addr, src)
                elif field != 0:
                    if base == "csrrs":
                        self.csr_write(addr, old | src)
                    else:
                        self.csr_write(addr, old & ~src)

                self.write_reg(rd, old)

                self.retire(
                    current_pc,
                    reg_write=(rd != 0),
                    rd=rd,
                    data=old,
                )

        # --------------------------------------------------------
        # ECALL: trap, mepc = the ECALL itself
        # --------------------------------------------------------

        elif op == "ecall":
            next_pc = self.take_trap(current_pc, CAUSE_ECALL)

        # --------------------------------------------------------
        # MRET: PC <- mepc, MIE <- MPIE, MPIE <- 1
        # --------------------------------------------------------

        elif op == "mret":
            status = self.csrs[CSR_MSTATUS]
            mie = MSTATUS_MIE if (status & MSTATUS_MPIE) else 0

            self.csrs[CSR_MSTATUS] = mie | MSTATUS_MPIE

            next_pc = self.csrs[CSR_MEPC]

            self.retire(current_pc)

        # --------------------------------------------------------
        # .word: the generator only emits illegal encodings
        # --------------------------------------------------------

        elif op == ".word":
            next_pc = self.take_trap(current_pc, CAUSE_ILLEGAL)

        else:
            raise ValueError(
                "Unsupported instruction: "
                f"{instr.text}"
            )

        self.pc = u32(next_pc)

    # ============================================================
    # Run
    # ============================================================

    def run(
        self,
        max_steps: int = 100_000,
    ) -> None:

        steps = 0

        while steps < max_steps:

            # Replay any RTL interrupt due at this boundary.
            self.take_injected_interrupts()

            # Execute the halt JAL once so it appears in the
            # expected retirement stream, then stop.
            if (
                self.halt_pc is not None
                and self.pc == self.halt_pc
            ):
                self.step()
                return

            self.step()

            steps += 1

        raise RuntimeError(
            "Reference model exceeded "
            f"{max_steps} instructions"
        )

    # ============================================================
    # Dumps
    # ============================================================

    def dump_retirements(self) -> None:
        for event in self.retire_events:

            print(
                "EXPECTED_RETIRE "
                f"pc={event.pc:08x} "
                f"regwrite={int(event.reg_write)} "
                f"rd={event.rd} "
                f"data={event.data:08x}"
            )

    def dump_traps(self) -> None:
        for event in self.trap_events:

            print(
                "EXPECTED_TRAP "
                f"kind={event.kind} "
                f"pc={event.pc:08x} "
                f"cause={event.cause:08x} "
                f"after={event.after}"
            )

    def dump_registers(self) -> None:
        for reg in range(32):
            value = self.read_reg(reg)

            print(
                f"REG x{reg} = "
                f"0x{value:08x} "
                f"({s32(value)})"
            )

    def dump_memory(self) -> None:
        for addr in sorted(
            self.memory
        ):
            value = self.memory[
                addr
            ]

            print(
                f"MEM 0x{addr:08x} = "
                f"0x{value:08x}"
            )


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "RV32I architectural "
            "reference model"
        )
    )

    parser.add_argument(
        "program",
        type=Path,
    )

    parser.add_argument(
        "--rtl-trace",
        type=Path,
        help=(
            "RTL simulation log (TRACE_RETIRE); timer interrupts "
            "are replayed at the retirement positions where the "
            "RTL took them"
        ),
    )

    args = parser.parse_args()

    model = RV32IReferenceModel()

    model.load_program(
        args.program
    )

    if args.rtl_trace is not None:
        model.injections = load_rtl_interrupts(args.rtl_trace)

    try:
        model.run()
    except ModelError as error:
        print(f"MODEL_ERROR: {error}")
        print(f"MODEL_ERROR: {error}", file=sys.stderr)
        raise SystemExit(1)

    model.dump_retirements()
    model.dump_traps()
    model.dump_registers()
    model.dump_memory()


if __name__ == "__main__":
    main()