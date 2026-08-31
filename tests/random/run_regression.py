#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path
import re
import subprocess
import sys
import time


COVERAGE_PATTERNS = {
    "exmem_rs1": re.compile(
        r"EX/MEM -> rs1 forwarding\s*:\s*(\d+)"
    ),
    "exmem_rs2": re.compile(
        r"EX/MEM -> rs2 forwarding\s*:\s*(\d+)"
    ),
    "memwb_rs1": re.compile(
        r"MEM/WB -> rs1 forwarding\s*:\s*(\d+)"
    ),
    "memwb_rs2": re.compile(
        r"MEM/WB -> rs2 forwarding\s*:\s*(\d+)"
    ),
    "load_use": re.compile(
        r"Load-use stalls\s*:\s*(\d+)"
    ),
    "branch_taken": re.compile(
        r"Taken branches\s*:\s*(\d+)"
    ),
    "jal": re.compile(
        r"JAL redirects\s*:\s*(\d+)"
    ),
    "jalr": re.compile(
        r"JALR redirects\s*:\s*(\d+)"
    ),
    "load": re.compile(
        r"Loads\s*:\s*(\d+)"
    ),
    "store": re.compile(
        r"Stores\s*:\s*(\d+)"
    ),
    "retire": re.compile(
        r"Retired instructions\s*:\s*(\d+)"
    ),
}


def parse_coverage(text: str) -> dict[str, int]:
    values: dict[str, int] = {}

    for name, pattern in COVERAGE_PATTERNS.items():
        match = pattern.search(text)

        if match:
            values[name] = int(match.group(1))
        else:
            values[name] = 0

    return values


def run_seed(
    software_dir: Path,
    seed: int,
    count: int,
) -> tuple[bool, str, dict[str, int]]:

    command = [
        "make",
        "random-sim",
        f"SEED={seed}",
        f"COUNT={count}",
    ]

    result = subprocess.run(
        command,
        cwd=software_dir,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )

    output = result.stdout

    passed = (
        result.returncode == 0
        and "RANDOM TEST PASSED" in output
    )

    coverage = parse_coverage(output)

    return passed, output, coverage


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Run seeded randomized RV32I "
            "pipeline regressions"
        )
    )

    parser.add_argument(
        "--seeds",
        type=int,
        default=100,
        help="Number of seeds to run",
    )

    parser.add_argument(
        "--start-seed",
        type=int,
        default=1,
        help="First seed",
    )

    parser.add_argument(
        "--count",
        type=int,
        default=300,
        help="Generated instructions per seed",
    )

    parser.add_argument(
        "--stop-on-fail",
        action="store_true",
        help="Stop immediately on first failure",
    )

    args = parser.parse_args()

    here = Path(__file__).resolve().parent

    repo_root = here.parent.parent
    software_dir = repo_root / "software"

    total_coverage = {
        name: 0
        for name in COVERAGE_PATTERNS
    }

    passed_count = 0
    failed_seeds: list[int] = []

    start_time = time.time()

    print(
        "========================================"
    )
    print(
        " RANDOMIZED RV32I REGRESSION"
    )
    print(
        "========================================"
    )

    print(
        f"Seeds       : {args.seeds}"
    )

    print(
        f"Start seed  : {args.start_seed}"
    )

    print(
        f"Instructions: {args.count} / seed"
    )

    print("")

    for index in range(args.seeds):
        seed = args.start_seed + index

        print(
            f"[{index + 1:4d}/{args.seeds}] "
            f"seed={seed:<8d}",
            end="",
            flush=True,
        )

        passed, output, coverage = run_seed(
            software_dir,
            seed,
            args.count,
        )

        for name, value in coverage.items():
            total_coverage[name] += value

        if passed:
            passed_count += 1

            print(
                " PASS "
                f"(retired={coverage['retire']})"
            )
        else:
            failed_seeds.append(seed)

            print(" FAIL")

            failure_log = (
                repo_root
                / "tests"
                / "random"
                / "generated"
                / f"failure_seed_{seed}.log"
            )

            failure_log.write_text(output)

            print(
                f"  Saved log: {failure_log}"
            )

            print(
                "  Reproduce with:"
            )

            print(
                "  make random-sim "
                f"SEED={seed} "
                f"COUNT={args.count} "
                "TRACE_RETIRE=1"
            )

            if args.stop_on_fail:
                break

    elapsed = time.time() - start_time

    print("")
    print(
        "========================================"
    )
    print(
        " REGRESSION SUMMARY"
    )
    print(
        "========================================"
    )

    completed = (
        passed_count
        + len(failed_seeds)
    )

    print(
        f"Completed : {completed}"
    )

    print(
        f"Passed    : {passed_count}"
    )

    print(
        f"Failed    : {len(failed_seeds)}"
    )

    print(
        f"Time      : {elapsed:.2f} s"
    )

    print("")
    print(
        "Accumulated coverage events:"
    )

    print(
        f"  EX/MEM -> rs1 : "
        f"{total_coverage['exmem_rs1']}"
    )

    print(
        f"  EX/MEM -> rs2 : "
        f"{total_coverage['exmem_rs2']}"
    )

    print(
        f"  MEM/WB -> rs1 : "
        f"{total_coverage['memwb_rs1']}"
    )

    print(
        f"  MEM/WB -> rs2 : "
        f"{total_coverage['memwb_rs2']}"
    )

    print(
        f"  Load-use      : "
        f"{total_coverage['load_use']}"
    )

    print(
        f"  Taken branch  : "
        f"{total_coverage['branch_taken']}"
    )

    print(
        f"  JAL           : "
        f"{total_coverage['jal']}"
    )

    print(
        f"  JALR          : "
        f"{total_coverage['jalr']}"
    )

    print(
        f"  Loads         : "
        f"{total_coverage['load']}"
    )

    print(
        f"  Stores        : "
        f"{total_coverage['store']}"
    )

    print(
        f"  Retired       : "
        f"{total_coverage['retire']}"
    )

    print(
        "========================================"
    )

    if failed_seeds:
        print(
            "FAILED SEEDS:"
        )

        for seed in failed_seeds:
            print(
                f"  {seed}"
            )

        raise SystemExit(1)

    print(
        "RANDOMIZED REGRESSION PASSED"
    )


if __name__ == "__main__":
    main()