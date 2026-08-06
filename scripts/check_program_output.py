#!/usr/bin/env python3

from pathlib import Path
import sys


def u32(value: int) -> int:
    return value & 0xFFFF_FFFF


def parse_expected(path: Path) -> dict[str, int]:
    expected: dict[str, int] = {}

    for raw_line in path.read_text().splitlines():
        line = raw_line.strip()

        if not line or line.startswith("#"):
            continue

        name, value = line.split("=", maxsplit=1)
        expected[name.strip()] = int(value.strip(), 0)

    return expected


def parse_actual(path: Path) -> dict[str, int]:
    actual: dict[str, int] = {}

    for raw_line in path.read_text().splitlines():
        line = raw_line.strip()

        if not line.startswith("REG "):
            continue

        _, name, value = line.split()
        actual[name] = int(value, 0)

    return actual


def main() -> None:
    if len(sys.argv) != 3:
        print(
            "Usage: check_program_output.py "
            "<simulation.log> <expected_file>"
        )
        raise SystemExit(2)

    log_path = Path(sys.argv[1])
    expected_path = Path(sys.argv[2])

    expected = parse_expected(expected_path)
    actual = parse_actual(log_path)

    failures = 0

    for name, expected_value in expected.items():
        if name not in actual:
            print(f"FAIL: {name} was not present in simulation output")
            failures += 1
            continue

        actual_value = u32(actual[name])
        expected_value = u32(expected_value)

        if actual_value != expected_value:
            print(
                f"FAIL: {name}: expected 0x{expected_value:08x}, "
                f"got 0x{actual_value:08x}"
            )
            failures += 1
        else:
            print(
                f"PASS: {name} = 0x{actual_value:08x}"
            )

    if failures:
        print(f"\nFAIL: {failures} mismatch(es)")
        raise SystemExit(1)

    print("\nPASS: all expected values matched")


if __name__ == "__main__":
    main()