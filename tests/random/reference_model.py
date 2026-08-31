#!/usr/bin/env python3

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
import re


U32_MASK = 0xFFFF_FFFF

MEM_PATTERN = re.compile(
    r"([-+]?(?:0[xX][0-9A-Fa-f]+|\d+))"
    r"\(x(\d+)\)"
)


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


@dataclass
class RetireEvent:
    pc: int
    reg_write: bool
    rd: int
    data: int


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

        self.memory[u32(addr)] = u32(
            value
        )

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

            if line.startswith("."):
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

            if line.startswith("."):
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

    args = parser.parse_args()

    model = RV32IReferenceModel()

    model.load_program(
        args.program
    )

    model.run()

    model.dump_retirements()
    model.dump_registers()
    model.dump_memory()


if __name__ == "__main__":
    main()