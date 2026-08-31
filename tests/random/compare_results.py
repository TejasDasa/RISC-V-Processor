#!/usr/bin/env python3

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import re
import sys


REGISTER_PATTERN = re.compile(
    r"REG\s+x(\d+)\s*=\s*"
    r"0x([0-9a-fA-F]+)"
)

MEMORY_PATTERN = re.compile(
    r"MEM\s+0x([0-9a-fA-F]+)"
    r"\s*=\s*"
    r"0x([0-9a-fA-F]+)"
)

EXPECTED_RETIRE_PATTERN = re.compile(
    r"EXPECTED_RETIRE\s+"
    r"pc=([0-9a-fA-F]+)\s+"
    r"regwrite=(\d+)\s+"
    r"rd=(\d+)\s+"
    r"data=([0-9a-fA-F]+)"
)

RTL_RETIRE_PATTERN = re.compile(
    r"RETIRE\s+"
    r"pc=([0-9a-fA-F]+)\s+"
    r"instr=([0-9a-fA-F]+)\s+"
    r"regwrite=(\d+)\s+"
    r"rd=(\d+)\s+"
    r"data=([0-9a-fA-F]+)"
)


@dataclass
class RetireEvent:
    pc: int
    reg_write: bool
    rd: int
    data: int


def parse_registers(
    path: Path,
) -> dict[int, int]:

    regs: dict[int, int] = {}

    for line in path.read_text().splitlines():
        match = REGISTER_PATTERN.search(
            line
        )

        if match:
            regs[int(match.group(1))] = int(
                match.group(2),
                16,
            )

    return regs


def parse_memory(
    path: Path,
) -> dict[int, int]:

    memory: dict[int, int] = {}

    for line in path.read_text().splitlines():
        match = MEMORY_PATTERN.search(
            line
        )

        if match:
            memory[
                int(match.group(1), 16)
            ] = int(
                match.group(2),
                16,
            )

    return memory


def parse_expected_retirements(
    path: Path,
) -> list[RetireEvent]:

    events: list[RetireEvent] = []

    for line in path.read_text().splitlines():
        match = (
            EXPECTED_RETIRE_PATTERN.search(
                line
            )
        )

        if not match:
            continue

        events.append(
            RetireEvent(
                pc=int(
                    match.group(1),
                    16,
                ),
                reg_write=bool(
                    int(match.group(2))
                ),
                rd=int(
                    match.group(3)
                ),
                data=int(
                    match.group(4),
                    16,
                ),
            )
        )

    return events


def parse_rtl_retirements(
    path: Path,
) -> list[RetireEvent]:

    events: list[RetireEvent] = []

    for line in path.read_text().splitlines():
        match = RTL_RETIRE_PATTERN.search(
            line
        )

        if not match:
            continue

        events.append(
            RetireEvent(
                pc=int(
                    match.group(1),
                    16,
                ),

                # group 2 is encoded instruction.
                reg_write=bool(
                    int(match.group(3))
                ),

                rd=int(
                    match.group(4)
                ),

                data=int(
                    match.group(5),
                    16,
                ),
            )
        )

    return events


def main() -> None:
    if len(sys.argv) != 3:
        print(
            "Usage: compare_results.py "
            "<reference.log> "
            "<simulation.log>"
        )

        raise SystemExit(2)

    reference_path = Path(
        sys.argv[1]
    )

    simulation_path = Path(
        sys.argv[2]
    )

    reference_regs = parse_registers(
        reference_path
    )

    simulation_regs = parse_registers(
        simulation_path
    )

    reference_mem = parse_memory(
        reference_path
    )

    simulation_mem = parse_memory(
        simulation_path
    )

    expected_retire = (
        parse_expected_retirements(
            reference_path
        )
    )

    rtl_retire = (
        parse_rtl_retirements(
            simulation_path
        )
    )

    failures = 0

    # ============================================================
    # Retirement sequence
    # ============================================================

    if len(rtl_retire) < len(
        expected_retire
    ):
        print(
            "FAIL: RTL retired only "
            f"{len(rtl_retire)} instructions, "
            f"reference expected "
            f"{len(expected_retire)}"
        )

        failures += 1

    retire_checks = min(
        len(expected_retire),
        len(rtl_retire),
    )

    for i in range(retire_checks):
        expected = expected_retire[i]
        actual = rtl_retire[i]

        mismatch = False

        if actual.pc != expected.pc:
            mismatch = True

        if (
            actual.reg_write
            != expected.reg_write
        ):
            mismatch = True

        # rd/data only matter when architectural
        # register state is modified.
        if expected.reg_write:
            if actual.rd != expected.rd:
                mismatch = True

            if actual.data != expected.data:
                mismatch = True

        if mismatch:
            print(
                f"FAIL: retirement #{i}"
            )

            print(
                "  expected: "
                f"pc=0x{expected.pc:08x} "
                f"regwrite={int(expected.reg_write)} "
                f"rd=x{expected.rd} "
                f"data=0x{expected.data:08x}"
            )

            print(
                "  actual:   "
                f"pc=0x{actual.pc:08x} "
                f"regwrite={int(actual.reg_write)} "
                f"rd=x{actual.rd} "
                f"data=0x{actual.data:08x}"
            )

            failures += 1

            # First retirement mismatch usually causes
            # everything afterward to shift, so don't print
            # thousands of cascading failures.
            break

    # ============================================================
    # Final registers
    # ============================================================

    for reg in range(32):
        if reg not in reference_regs:
            print(
                f"ERROR: reference missing x{reg}"
            )

            failures += 1
            continue

        if reg not in simulation_regs:
            print(
                f"ERROR: simulation missing x{reg}"
            )

            failures += 1
            continue

        expected = reference_regs[reg]
        actual = simulation_regs[reg]

        if actual != expected:
            print(
                f"FAIL: x{reg}: "
                f"expected 0x{expected:08x}, "
                f"got 0x{actual:08x}"
            )

            failures += 1

    # ============================================================
    # Final memory
    # ============================================================

    memory_checks = 0

    for addr, expected in sorted(
        reference_mem.items()
    ):
        memory_checks += 1

        if addr not in simulation_mem:
            print(
                "ERROR: simulation missing "
                f"memory address "
                f"0x{addr:08x}"
            )

            failures += 1
            continue

        actual = simulation_mem[
            addr
        ]

        if actual != expected:
            print(
                "FAIL: "
                f"MEM[0x{addr:08x}]: "
                f"expected 0x{expected:08x}, "
                f"got 0x{actual:08x}"
            )

            failures += 1

    # ============================================================
    # Result
    # ============================================================

    if failures:
        print(
            "\nRANDOM TEST FAILED: "
            f"{failures} mismatch(es)"
        )

        raise SystemExit(1)

    print(
        "\nRANDOM TEST PASSED"
    )

    print(
        f"First {len(expected_retire)} "
        "retired instructions matched "
        "the architectural model."
    )

    print(
        "All 32 architectural "
        "registers matched."
    )

    print(
        f"All {memory_checks} modified "
        "memory location(s) matched."
    )


if __name__ == "__main__":
    main()