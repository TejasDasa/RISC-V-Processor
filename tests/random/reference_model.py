#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path
import re


U32_MASK = 0xFFFF_FFFF

MEM_PATTERN = re.compile(
    r"([-+]?(?:0[xX][0-9A-Fa-f]+|\d+))\(x(\d+)\)"
)


def u32(value: int) -> int:
    return value & U32_MASK


def s32(value: int) -> int:
    value &= U32_MASK

    if value & 0x8000_0000:
        return value - 0x1_0000_0000

    return value


def parse_reg(token: str) -> int:
    token = token.strip()

    match = re.fullmatch(r"x(\d+)", token)

    if match is None:
        raise ValueError(f"Invalid register: {token}")

    reg = int(match.group(1))

    if not 0 <= reg <= 31:
        raise ValueError(f"Register out of range: {token}")

    return reg


def parse_imm(token: str) -> int:
    return int(token.strip(), 0)


def parse_mem_operand(token: str) -> tuple[int, int]:
    match = MEM_PATTERN.fullmatch(token.strip())

    if match is None:
        raise ValueError(f"Invalid memory operand: {token}")

    offset = int(match.group(1), 0)
    reg = int(match.group(2))

    return offset, reg


class RV32IReferenceModel:
    def __init__(self) -> None:
        self.regs = [0] * 32
        self.memory: dict[int, int] = {}

    def read_reg(self, reg: int) -> int:
        if reg == 0:
            return 0

        return self.regs[reg]

    def write_reg(self, reg: int, value: int) -> None:
        if reg == 0:
            return

        self.regs[reg] = u32(value)

    def load_word(self, addr: int) -> int:
        return self.memory.get(addr, 0)

    def store_word(self, addr: int, value: int) -> None:
        self.memory[addr] = u32(value)

    def execute(self, line: str) -> None:
        # Remove comments.
        line = line.split("#", 1)[0].strip()

        if not line:
            return

        # Ignore labels and assembler directives.
        if line.endswith(":"):
            return

        if line.startswith("."):
            return

        # Normalize commas into spaces.
        tokens = line.replace(",", " ").split()

        if not tokens:
            return

        op = tokens[0].lower()

        # --------------------------------------------------------
        # Immediate arithmetic
        # --------------------------------------------------------

        if op == "addi":
            rd = parse_reg(tokens[1])
            rs1 = parse_reg(tokens[2])
            imm = parse_imm(tokens[3])

            result = self.read_reg(rs1) + imm

            self.write_reg(rd, result)
            return

        # --------------------------------------------------------
        # Register-register arithmetic / logic
        # --------------------------------------------------------

        if op in {
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
                result = a << (b & 0x1F)

            elif op == "srl":
                result = u32(a) >> (b & 0x1F)

            elif op == "slt":
                result = int(s32(a) < s32(b))

            elif op == "sltu":
                result = int(u32(a) < u32(b))

            else:
                raise AssertionError("unreachable")

            self.write_reg(rd, result)
            return

        # --------------------------------------------------------
        # Loads
        # --------------------------------------------------------

        if op == "lw":
            rd = parse_reg(tokens[1])

            offset, rs1 = parse_mem_operand(tokens[2])

            addr = u32(
                self.read_reg(rs1) + offset
            )

            self.write_reg(
                rd,
                self.load_word(addr)
            )

            return

        # --------------------------------------------------------
        # Stores
        # --------------------------------------------------------

        if op == "sw":
            rs2 = parse_reg(tokens[1])

            offset, rs1 = parse_mem_operand(tokens[2])

            addr = u32(
                self.read_reg(rs1) + offset
            )

            self.store_word(
                addr,
                self.read_reg(rs2)
            )

            return

        # --------------------------------------------------------
        # Halt loop
        # --------------------------------------------------------

        if op == "jal":
            return

        raise ValueError(
            f"Unsupported instruction in reference model: {line}"
        )

    def run_file(self, path: Path) -> None:
        for line_number, raw_line in enumerate(
            path.read_text().splitlines(),
            start=1,
        ):
            try:
                self.execute(raw_line)
            except Exception as error:
                raise RuntimeError(
                    f"{path}:{line_number}: {error}"
                ) from error

    def dump_registers(self) -> None:
        for reg in range(32):
            value = self.read_reg(reg)

            print(
                f"REG x{reg} = "
                f"0x{value:08x} "
                f"({s32(value)})"
            )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Tiny RV32I architectural reference model"
    )

    parser.add_argument(
        "program",
        type=Path,
        help="Generated assembly program",
    )

    args = parser.parse_args()

    model = RV32IReferenceModel()

    model.run_file(args.program)

    model.dump_registers()


if __name__ == "__main__":
    main()