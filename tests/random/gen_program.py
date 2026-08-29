#!/usr/bin/env python3

import random
import sys
from pathlib import Path


REGS = list(range(1, 16))

last_rd = None

def reg() -> int:
    return random.choice(REGS)


def imm12() -> int:
    return random.randint(-128, 127)


def generate_instruction(last_rd: int | None):
    op = random.choice([
        "addi",
        "add",
        "sub",
        "and",
        "or",
        "xor",
        "sll",
        "srl",
        "slt",
        "sltu",
    ])

    rd = reg()

    if last_rd is not None and random.random() < 0.60:
        rs1 = last_rd
    else:
        rs1 = reg()

    if op == "addi":
        instr = f"addi x{rd}, x{rs1}, {imm12()}"
    else:
        if last_rd is not None and random.random() < 0.30:
            rs2 = last_rd
        else:
            rs2 = reg()

        instr = f"{op} x{rd}, x{rs1}, x{rs2}"

    return instr, rd


def main() -> None:
    seed = int(sys.argv[1]) if len(sys.argv) > 1 else 1
    count = int(sys.argv[2]) if len(sys.argv) > 2 else 100

    random.seed(seed)

    lines = [
        ".section .text.init",
        ".globl _start",
        "",
        "_start:",
    ]

    # Give registers deterministic initial values.
    for r in REGS:
        lines.append(f"    addi x{r}, x0, {r}")

    lines.append("")

    last_rd = None
    for _ in range(count):
        instr, last_rd = generate_instruction(last_rd)
        lines.append(f"    {instr}")

    lines += [
        "",
        "halt:",
        "    jal x0, halt",
        "",
    ]

    HERE = Path(__file__).resolve().parent

    output = HERE / "generated" / "random_test.S"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(lines))

    print(f"Generated {count} instructions")
    print(f"Seed: {seed}")
    print(f"Output: {output}")


if __name__ == "__main__":
    main()