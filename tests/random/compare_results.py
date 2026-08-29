#!/usr/bin/env python3

import re
import sys
from pathlib import Path


REGISTER_PATTERN = re.compile(
    r"REG\s+x(\d+)\s*=\s*0x([0-9a-fA-F]+)"
)


def parse_registers(path: Path) -> dict[int, int]:
    regs = {}

    for line in path.read_text().splitlines():
        match = REGISTER_PATTERN.search(line)

        if match:
            reg = int(match.group(1))
            value = int(match.group(2), 16)

            regs[reg] = value

    return regs


def main() -> None:
    if len(sys.argv) != 3:
        print(
            "Usage: compare_results.py "
            "<reference.log> <simulation.log>"
        )
        raise SystemExit(2)

    reference_path = Path(sys.argv[1])
    simulation_path = Path(sys.argv[2])

    reference = parse_registers(reference_path)
    simulation = parse_registers(simulation_path)

    failures = 0

    for reg in range(32):
        if reg not in reference:
            print(f"ERROR: reference missing x{reg}")
            failures += 1
            continue

        if reg not in simulation:
            print(f"ERROR: simulation missing x{reg}")
            failures += 1
            continue

        expected = reference[reg]
        actual = simulation[reg]

        if actual != expected:
            print(
                f"FAIL: x{reg}: "
                f"expected 0x{expected:08x}, "
                f"got 0x{actual:08x}"
            )
            failures += 1

    if failures:
        print(f"\nRANDOM TEST FAILED: {failures} mismatch(es)")
        raise SystemExit(1)

    print("\nRANDOM TEST PASSED")
    print("All 32 architectural registers matched.")


if __name__ == "__main__":
    main()