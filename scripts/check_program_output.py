#!/usr/bin/env python3

from dataclasses import dataclass
from pathlib import Path
import operator
import re
import sys
from typing import Callable


U32_MASK = 0xFFFF_FFFF

COMPARISON_PATTERN = re.compile(
    r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*"
    r"(==|!=|>=|<=|=|>|<)\s*"
    r"([-+]?(?:0[xX][0-9A-Fa-f]+|0[bB][01]+|0[oO][0-7]+|\d+))\s*$"
)


@dataclass(frozen=True)
class Expectation:
    name: str
    comparison: str
    value: int


COMPARISONS: dict[str, Callable[[int, int], bool]] = {
    "=": operator.eq,
    "==": operator.eq,
    "!=": operator.ne,
    ">": operator.gt,
    ">=": operator.ge,
    "<": operator.lt,
    "<=": operator.le,
}


def u32(value: int) -> int:
    return value & U32_MASK


def s32(value: int) -> int:
    value = u32(value)

    if value & 0x8000_0000:
        return value - 0x1_0000_0000

    return value


def parse_expected(path: Path) -> list[Expectation]:
    expectations: list[Expectation] = []

    for line_number, raw_line in enumerate(
        path.read_text().splitlines(),
        start=1,
    ):
        line = raw_line.strip()

        if not line or line.startswith("#"):
            continue

        match = COMPARISON_PATTERN.fullmatch(line)

        if match is None:
            raise ValueError(
                f"{path}:{line_number}: invalid expectation: {raw_line!r}"
            )

        name, comparison, value_text = match.groups()

        expectations.append(
            Expectation(
                name=name,
                comparison=comparison,
                value=int(value_text, 0),
            )
        )

    return expectations


def parse_actual(path: Path) -> dict[str, int]:
    actual: dict[str, int] = {}

    for raw_line in path.read_text().splitlines():
        line = raw_line.strip()

        if not line.startswith("REG "):
            continue

        parts = line.split()

        if len(parts) != 3:
            continue

        _, name, value_text = parts

        try:
            actual[name] = int(value_text, 0)
        except ValueError:
            continue

    return actual


def comparison_uses_signed_values(expectation: Expectation) -> bool:
    """
    Equality compares 32-bit bit patterns.

    Ordered comparisons use signed interpretation when the expected value
    is written as a negative number. Otherwise they use unsigned values.
    """
    return (
        expectation.comparison in {">", ">=", "<", "<="}
        and expectation.value < 0
    )


def format_value(value: int) -> str:
    return (
        f"0x{u32(value):08x} "
        f"(unsigned {u32(value)}, signed {s32(value)})"
    )


def main() -> None:
    if len(sys.argv) != 3:
        print(
            "Usage: check_program_output.py "
            "<simulation.log> <expected_file>"
        )
        raise SystemExit(2)

    log_path = Path(sys.argv[1])
    expected_path = Path(sys.argv[2])

    try:
        expectations = parse_expected(expected_path)
    except (OSError, ValueError) as error:
        print(f"ERROR: {error}")
        raise SystemExit(2)

    try:
        actual = parse_actual(log_path)
    except OSError as error:
        print(f"ERROR: {error}")
        raise SystemExit(2)

    failures = 0

    for expectation in expectations:
        if expectation.name not in actual:
            print(
                f"FAIL: {expectation.name} was not present "
                "in simulation output"
            )
            failures += 1
            continue

        comparison_function = COMPARISONS[expectation.comparison]

        raw_actual = actual[expectation.name]
        raw_expected = expectation.value

        if expectation.comparison in {"=", "==", "!="}:
            actual_value = u32(raw_actual)
            expected_value = u32(raw_expected)
            interpretation = "32-bit"
        elif comparison_uses_signed_values(expectation):
            actual_value = s32(raw_actual)
            expected_value = raw_expected
            interpretation = "signed"
        else:
            actual_value = u32(raw_actual)
            expected_value = u32(raw_expected)
            interpretation = "unsigned"

        passed = comparison_function(actual_value, expected_value)

        expression = (
            f"{expectation.name} "
            f"{expectation.comparison} "
            f"{expectation.value}"
        )

        if passed:
            print(
                f"PASS: {expression} "
                f"[actual {format_value(raw_actual)}, "
                f"{interpretation} comparison]"
            )
        else:
            print(
                f"FAIL: {expression}; "
                f"actual was {format_value(raw_actual)} "
                f"[{interpretation} comparison]"
            )
            failures += 1

    if failures:
        print(f"\nFAIL: {failures} mismatch(es)")
        raise SystemExit(1)

    print("\nPASS: all expected values matched")


if __name__ == "__main__":
    main()