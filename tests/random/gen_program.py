#!/usr/bin/env python3

from __future__ import annotations

import random
import sys
from pathlib import Path


# ============================================================
# Register allocation
# ============================================================

# Random data registers
REGS = list(range(1, 16))

# Reserved registers
BRANCH_RS1 = 16
BRANCH_RS2 = 17
JAL_LINK = 18
HELPER_COUNT = 19
DMEM_BASE_REG = 20
CALL_LINK = 31


# ============================================================
# Memory configuration
# ============================================================

DMEM_BASE_ADDR = 0x0001_0000
DMEM_WORDS = 64


# ============================================================
# Helpers
# ============================================================

def reg() -> int:
    return random.choice(REGS)


def imm12() -> int:
    return random.randint(-128, 127)


def mem_offset() -> int:
    return random.randrange(
        0,
        DMEM_WORDS * 4,
        4,
    )


def is_label(line: str) -> bool:
    return line.strip().endswith(":")


# ============================================================
# ALU generation
# ============================================================

def generate_alu_instruction(
    last_rd: int | None,
) -> tuple[list[str], int]:

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

    if (
        last_rd is not None
        and random.random() < 0.60
    ):
        rs1 = last_rd
    else:
        rs1 = reg()

    if op == "addi":
        instr = (
            f"addi x{rd}, x{rs1}, {imm12()}"
        )

    else:
        if (
            last_rd is not None
            and random.random() < 0.30
        ):
            rs2 = last_rd
        else:
            rs2 = reg()

        instr = (
            f"{op} x{rd}, x{rs1}, x{rs2}"
        )

    return [instr], rd


# ============================================================
# Load generation
# ============================================================

def generate_load() -> tuple[str, int]:
    rd = reg()
    offset = mem_offset()

    instr = (
        f"lw x{rd}, "
        f"{offset}(x{DMEM_BASE_REG})"
    )

    return instr, rd


# ============================================================
# Store generation
# ============================================================

def generate_store(
    last_rd: int | None,
) -> str:

    offset = mem_offset()

    # Bias store data toward the previous result
    # to exercise forwarding.
    if (
        last_rd is not None
        and random.random() < 0.70
    ):
        rs2 = last_rd
    else:
        rs2 = reg()

    return (
        f"sw x{rs2}, "
        f"{offset}(x{DMEM_BASE_REG})"
    )


# ============================================================
# Branch generation
# ============================================================

def branch_values(
    op: str,
    taken: bool,
) -> tuple[int, int]:

    if op == "beq":
        return (5, 5) if taken else (5, 6)

    if op == "bne":
        return (5, 6) if taken else (5, 5)

    if op in {"blt", "bltu"}:
        return (1, 2) if taken else (2, 1)

    if op in {"bge", "bgeu"}:
        return (2, 1) if taken else (1, 2)

    raise ValueError(
        f"Unknown branch op: {op}"
    )


def generate_branch(
    label_id: int,
) -> tuple[list[str], int]:

    op = random.choice([
        "beq",
        "bne",
        "blt",
        "bge",
        "bltu",
        "bgeu",
    ])

    taken = (
        random.random() < 0.50
    )

    a, b = branch_values(
        op,
        taken,
    )

    label = (
        f"branch_target_{label_id}"
    )

    victim_rd = reg()

    bundle = [
        f"addi x{BRANCH_RS1}, x0, {a}",
        f"addi x{BRANCH_RS2}, x0, {b}",

        (
            f"{op} "
            f"x{BRANCH_RS1}, "
            f"x{BRANCH_RS2}, "
            f"{label}"
        ),

        # Executes only if branch is not taken.
        (
            f"addi x{victim_rd}, "
            f"x{victim_rd}, 1"
        ),

        f"{label}:",
    ]

    return bundle, victim_rd


# ============================================================
# JAL generation
# ============================================================

def generate_jal(
    label_id: int,
) -> tuple[list[str], int]:

    label = (
        f"jal_target_{label_id}"
    )

    victim_rd = reg()

    bundle = [
        f"jal x{JAL_LINK}, {label}",

        # Wrong-path instruction.
        (
            f"addi x{victim_rd}, "
            f"x{victim_rd}, 1"
        ),

        f"{label}:",
    ]

    return bundle, JAL_LINK


# ============================================================
# JAL / JALR helper call
# ============================================================

def generate_helper_call(
) -> tuple[list[str], int]:

    bundle = [
        f"jal x{CALL_LINK}, helper"
    ]

    return bundle, CALL_LINK


# ============================================================
# Random instruction / bundle selection
# ============================================================

def generate_instruction(
    last_rd: int | None,
    label_id: int,
) -> tuple[list[str], int | None, int]:

    choice = random.random()

    # --------------------------------------------------------
    # 45% ALU
    # --------------------------------------------------------

    if choice < 0.45:
        instructions, rd = (
            generate_alu_instruction(
                last_rd
            )
        )

        return (
            instructions,
            rd,
            label_id,
        )

    # --------------------------------------------------------
    # 15% load
    # --------------------------------------------------------

    if choice < 0.60:
        load_instr, rd = (
            generate_load()
        )

        instructions = [
            load_instr
        ]

        # Deliberately create load-use hazards.
        if random.random() < 0.60:
            dest = reg()

            instructions.append(
                f"addi x{dest}, "
                f"x{rd}, "
                f"{imm12()}"
            )

            return (
                instructions,
                dest,
                label_id,
            )

        return (
            instructions,
            rd,
            label_id,
        )

    # --------------------------------------------------------
    # 15% store
    # --------------------------------------------------------

    if choice < 0.75:
        return (
            [
                generate_store(
                    last_rd
                )
            ],
            last_rd,
            label_id,
        )

    # --------------------------------------------------------
    # 15% conditional branch
    # --------------------------------------------------------

    if choice < 0.90:
        instructions, rd = (
            generate_branch(
                label_id
            )
        )

        return (
            instructions,
            rd,
            label_id + 1,
        )

    # --------------------------------------------------------
    # 5% JAL
    # --------------------------------------------------------

    if choice < 0.95:
        instructions, rd = (
            generate_jal(
                label_id
            )
        )

        return (
            instructions,
            rd,
            label_id + 1,
        )

    # --------------------------------------------------------
    # 5% helper call using JAL + JALR
    # --------------------------------------------------------

    instructions, rd = (
        generate_helper_call()
    )

    return (
        instructions,
        rd,
        label_id,
    )


# ============================================================
# Validation
# ============================================================

def validate_labels(
    lines: list[str],
) -> None:

    labels: set[str] = set()
    references: list[
        tuple[str, str]
    ] = []

    for raw_line in lines:
        line = raw_line.strip()

        if not line:
            continue

        if line.startswith("."):
            continue

        if line.endswith(":"):
            labels.add(
                line[:-1]
            )
            continue

        tokens = (
            line
            .replace(",", " ")
            .split()
        )

        if not tokens:
            continue

        op = tokens[0].lower()

        if op in {
            "beq",
            "bne",
            "blt",
            "bge",
            "bltu",
            "bgeu",
        }:
            references.append(
                (
                    op,
                    tokens[3],
                )
            )

        elif op == "jal":
            references.append(
                (
                    op,
                    tokens[2],
                )
            )

    missing = []

    for op, label in references:
        if label not in labels:
            missing.append(
                (op, label)
            )

    if missing:
        messages = [
            f"{op} -> {label}"
            for op, label
            in missing
        ]

        raise RuntimeError(
            "Generated program contains "
            "undefined labels:\n  "
            + "\n  ".join(messages)
        )


# ============================================================
# Main
# ============================================================

def main() -> None:
    seed = (
        int(sys.argv[1])
        if len(sys.argv) > 1
        else 1
    )

    count = (
        int(sys.argv[2])
        if len(sys.argv) > 2
        else 100
    )

    random.seed(seed)

    lines = [
        ".section .text.init",
        ".globl _start",
        "",
        "_start:",
        "",

        # x20 = 0x0001_0000
        (
            f"    lui "
            f"x{DMEM_BASE_REG}, "
            f"0x10"
        ),

        # Helper-call counter.
        (
            f"    addi "
            f"x{HELPER_COUNT}, "
            f"x0, 0"
        ),

        "",
    ]

    # Deterministic initial register values.
    for r in REGS:
        lines.append(
            f"    addi x{r}, x0, {r}"
        )

    lines.append("")

    last_rd: int | None = None

    label_id = 0
    generated_count = 0

    while generated_count < count:

        (
            instructions,
            next_last_rd,
            next_label_id,
        ) = generate_instruction(
            last_rd,
            label_id,
        )

        bundle_instruction_count = sum(
            1
            for instr
            in instructions
            if not is_label(instr)
        )

        # Do not emit only part of a branch/JAL bundle.
        #
        # If this bundle would exceed COUNT, stop cleanly.
        if (
            generated_count
            + bundle_instruction_count
            > count
        ):
            break

        # Append the ENTIRE bundle atomically.
        for instr in instructions:
            lines.append(
                f"    {instr}"
            )

        generated_count += (
            bundle_instruction_count
        )

        last_rd = next_last_rd
        label_id = next_label_id

    # ========================================================
    # Program end
    # ========================================================

    lines += [
        "",
        "halt:",
        "    jal x0, halt",
        "",

        # Shared helper for JAL/JALR testing.
        "helper:",

        (
            f"    addi "
            f"x{HELPER_COUNT}, "
            f"x{HELPER_COUNT}, 1"
        ),

        (
            f"    jalr "
            f"x0, "
            f"0(x{CALL_LINK})"
        ),

        "",
    ]

    # Make sure generator bugs are caught here rather
    # than later by the assembler/reference model.
    validate_labels(
        lines
    )

    here = (
        Path(__file__)
        .resolve()
        .parent
    )

    output = (
        here
        / "generated"
        / "random_test.S"
    )

    output.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    output.write_text(
        "\n".join(lines)
        + "\n"
    )

    print(
        f"Generated "
        f"{generated_count} "
        f"main-program instructions"
    )

    print(
        f"Seed: {seed}"
    )

    print(
        f"Output: {output}"
    )

    print(
        "DMEM range: "
        f"0x{DMEM_BASE_ADDR:08x} - "
        f"0x{
            DMEM_BASE_ADDR
            + DMEM_WORDS * 4
            - 4
        :08x}"
    )


if __name__ == "__main__":
    main()