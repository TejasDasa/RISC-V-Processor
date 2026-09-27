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

# Trap / interrupt harness (x21-x27)
TRAP_COUNT = 21      # synchronous traps taken
IRQ_COUNT = 22       # interrupts taken
TRAP_TMP = 23        # handler scratch
CAUSE_ACCUM = 24     # xor of every mcause seen
NEXT_COMPARE = 25    # next timer compare value
TIMER_BASE = 26      # TIMER_COMPARE address
MEPC_ACCUM = 27      # sum of every mepc seen

# The handler sits right after the first jump, so mtvec is a small
# constant the reference model can use without the "la" pseudo-op.
TRAP_HANDLER_ADDR = 4


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
# CSR generation
# ============================================================

# CSRs the random program may read. mip is excluded: its value
# depends on timer cycles, which the reference model does not model.
CSR_READABLE = [
    "mstatus", "mie", "mtvec", "mepc", "mcause", "mscratch",
]

# CSRs the random program may write. mstatus / mie / mtvec belong to
# the trap harness; mepc / mcause are safe (every trap rewrites
# them before the handler reads them).
CSR_WRITABLE = [
    "mscratch", "mscratch", "mscratch", "mepc", "mcause",
]


def generate_csr(
    last_rd: int | None,
) -> tuple[list[str], int]:

    rd = reg()
    kind = random.random()

    # Plain read: csrrs rd, csr, x0
    if kind < 0.30:
        csr = random.choice(CSR_READABLE)
        return [f"csrrs x{rd}, {csr}, x0"], rd

    csr = random.choice(CSR_WRITABLE)

    # Register forms, biased toward the previous result so the CSR
    # source operand exercises forwarding. rs1 = x0 exercises the
    # CSRRS / CSRRC write suppression.
    if kind < 0.65:
        op = random.choice(["csrrw", "csrrs", "csrrc"])

        if last_rd is not None and random.random() < 0.60:
            rs1 = last_rd
        else:
            rs1 = random.choice([0] + REGS)

        bundle = [f"{op} x{rd}, {csr}, x{rs1}"]

    # Immediate forms; zimm = 0 exercises write suppression.
    else:
        op = random.choice(["csrrwi", "csrrsi", "csrrci"])

        if random.random() < 0.25:
            zimm = 0
        else:
            zimm = random.randint(1, 31)

        bundle = [f"{op} x{rd}, {csr}, {zimm}"]

    # Usually read the CSR straight back: a back-to-back CSR
    # read-after-write that makes the write architecturally visible.
    if random.random() < 0.70:
        readback = reg()
        bundle.append(f"csrrs x{readback}, {csr}, x0")
        return bundle, readback

    return bundle, rd


# ============================================================
# Synchronous trap generation
# ============================================================

# Encodings that always raise an illegal-instruction exception.
ILLEGAL_WORDS = [
    0x0000_0000,    # all zeros
    0xFFFF_FFFF,    # all ones (opcode 0x7f)
    0xFE10_8633,    # ADD with funct7 = 0x7f
    0x0095_3423,    # SD (RV64 only)
]


def generate_ecall() -> list[str]:
    return ["ecall"]


def generate_illegal() -> list[str]:
    if random.random() < 0.5:
        # Access to an unimplemented CSR (0x7c0 is not present).
        # The destination must not be written.
        return [f"csrrw x{reg()}, 0x7c0, x{reg()}"]

    return [f".word 0x{random.choice(ILLEGAL_WORDS):08x}"]


# ============================================================
# Random instruction / bundle selection
# ============================================================

def generate_instruction(
    last_rd: int | None,
    label_id: int,
) -> tuple[list[str], int | None, int]:

    choice = random.random()

    # --------------------------------------------------------
    # 33% ALU
    # --------------------------------------------------------

    if choice < 0.33:
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
    # 8% CSR access
    # --------------------------------------------------------

    if choice < 0.41:
        instructions, rd = generate_csr(last_rd)
        return instructions, rd, label_id

    # --------------------------------------------------------
    # 2% ECALL, 2% illegal instruction (synchronous traps)
    # --------------------------------------------------------

    if choice < 0.43:
        return generate_ecall(), last_rd, label_id

    if choice < 0.45:
        return generate_illegal(), last_rd, label_id

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

    # Timer interrupt schedule (in RTL cycles; the reference model
    # takes interrupts where the RTL trace says they happened).
    first_irq = random.randint(20, 300)
    irq_interval = random.randint(60, 250)

    t = TRAP_TMP

    lines = [
        ".section .text.init",
        ".globl _start",
        "",
        "_start:",
        "    jal x0, setup",
        "",

        # ----------------------------------------------------
        # Trap handler at TRAP_HANDLER_ADDR (= 4).
        #
        #   exception: count it, return to mepc + 4
        #   interrupt: count it, push the timer compare forward
        #              (clears the IRQ), return to mepc
        #
        # Only x21-x27 are touched, so random code state survives.
        # ----------------------------------------------------
        "trap_handler:",
        f"    csrrs x{t}, mcause, x0",
        f"    xor x{CAUSE_ACCUM}, x{CAUSE_ACCUM}, x{t}",
        f"    blt x{t}, x0, trap_irq",
        f"    addi x{TRAP_COUNT}, x{TRAP_COUNT}, 1",
        f"    csrrs x{t}, mepc, x0",
        f"    add x{MEPC_ACCUM}, x{MEPC_ACCUM}, x{t}",
        f"    addi x{t}, x{t}, 4",
        f"    csrrw x0, mepc, x{t}",
        "    mret",
        "trap_irq:",
        f"    addi x{IRQ_COUNT}, x{IRQ_COUNT}, 1",
        f"    csrrs x{t}, mepc, x0",
        f"    add x{MEPC_ACCUM}, x{MEPC_ACCUM}, x{t}",
        f"    addi x{NEXT_COMPARE}, x{NEXT_COMPARE}, {irq_interval}",
        f"    sw x{NEXT_COMPARE}, 0(x{TIMER_BASE})",
        "    mret",
        "",

        "setup:",
        f"    addi x{t}, x0, {TRAP_HANDLER_ADDR}",
        f"    csrrw x0, mtvec, x{t}",
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

        # Trap harness counters.
        f"    addi x{TRAP_COUNT}, x0, 0",
        f"    addi x{IRQ_COUNT}, x0, 0",
        f"    addi x{CAUSE_ACCUM}, x0, 0",
        f"    addi x{MEPC_ACCUM}, x0, 0",

        # Timer: compare = first_irq, then enable counter + IRQ.
        # The counter starts at 0 when enabled, so no timer reads
        # (which the reference model cannot predict) are needed.
        f"    lui x{TIMER_BASE}, 0x10000",
        f"    addi x{TIMER_BASE}, x{TIMER_BASE}, 0x14",
        f"    addi x{NEXT_COMPARE}, x0, {first_irq}",
        f"    sw x{NEXT_COMPARE}, 0(x{TIMER_BASE})",
        f"    addi x{t}, x0, 3",
        f"    sw x{t}, 4(x{TIMER_BASE})",

        # mie.MTIE, then mstatus.MIE
        f"    addi x{t}, x0, 0x80",
        f"    csrrs x0, mie, x{t}",
        f"    addi x{t}, x0, 8",
        f"    csrrs x0, mstatus, x{t}",

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
        # No interrupts while spinning in the halt loop.
        "    csrrw x0, mstatus, x0",
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
        f"Timer IRQ: first at cycle {first_irq}, "
        f"then every {irq_interval} cycles"
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