#!/usr/bin/env python3
"""
Print selected wave_probe signals from a demo VCD, one row per cycle.

    python3 tests/waveforms/vcd_peek.py waves/01_forwarding_chain.vcd \
        cycle ex_asm fwd_rs1_src fwd_rs2_src ex_alu_result

Values are sampled just before each rising clock edge. Signals that
end in _asm or _src are decoded as ASCII; others print as hex.
Useful for checking a waveform (and writing README tables) without
opening GTKWave.
"""

from __future__ import annotations

import sys
from pathlib import Path


ASCII_SUFFIXES = ("_asm", "_src")


def parse_vcd(path: Path):
    ids: dict[str, list[str]] = {}  # vcd id -> signal names (aliases share an id)
    widths: dict[str, int] = {}
    scope: list[str] = []
    changes: list[tuple[int, str, str]] = []
    time = 0
    in_defs = True

    for raw in path.read_text().splitlines():
        line = raw.strip()
        if not line:
            continue

        if in_defs:
            tok = line.split()
            if tok[0] == "$scope":
                scope.append(tok[2])
            elif tok[0] == "$upscope":
                scope.pop()
            elif tok[0] == "$var":
                # Only the probe scope: wave_tb.cpu.<name>
                if scope[-1] == "cpu":
                    ids.setdefault(tok[3], []).append(tok[4])
                    widths[tok[4]] = int(tok[2])
            elif tok[0] == "$enddefinitions":
                in_defs = False
            continue

        if line[0] == "#":
            time = int(line[1:])
        elif line[0] == "b":
            value, vid = line[1:].split()
            for name in ids.get(vid, []):
                changes.append((time, name, value))
        elif line[0] in "01xz":
            vid = line[1:]
            for name in ids.get(vid, []):
                changes.append((time, name, line[0]))

    return widths, changes


def to_text(bits: str) -> str:
    bits = bits.replace("x", "0").replace("z", "0")
    bits = bits.zfill((len(bits) + 7) // 8 * 8)
    chars = []
    for i in range(0, len(bits), 8):
        c = int(bits[i:i + 8], 2)
        if c:
            chars.append(chr(c))
    return "".join(chars)


def fmt(name: str, bits: str, width: int) -> str:
    if name.endswith(ASCII_SUFFIXES):
        return to_text(bits)
    if "x" in bits or "z" in bits:
        return "x"
    value = int(bits, 2)
    if width == 1:
        return str(value)
    if name == "cycle":
        return str(value)
    return f"{value:0{(width + 3) // 4}x}"


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 1

    path = Path(sys.argv[1])
    names = sys.argv[2:]
    widths, changes = parse_vcd(path)

    missing = [n for n in names if n not in widths]
    if missing:
        print(f"unknown signals: {missing}")
        print("available:", " ".join(sorted(widths)))
        return 1

    # Rising edges of clk; sample the state as it was before the
    # edge's timestamp (registers update at the same timestamp).
    state: dict[str, str] = {}
    before: dict[str, str] = {}
    rows: list[list[str]] = []
    cur_time = -1

    for time, name, value in changes:
        if time != cur_time:
            before = dict(state)
            cur_time = time
        if (name == "clk" and value == "1" and
                before.get("clk", "0") == "0" and
                before.get("rst") == "0"):
            rows.append([
                fmt(n, before.get(n, "x"), widths[n]) for n in names
            ])
        state[name] = value

    col = [max(len(n), *(len(r[i]) for r in rows)) for i, n in
           enumerate(names)]
    print(" | ".join(n.ljust(col[i]) for i, n in enumerate(names)))
    print("-+-".join("-" * c for c in col))
    for r in rows:
        print(" | ".join(v.ljust(col[i]) for i, v in enumerate(r)))

    return 0


if __name__ == "__main__":
    sys.exit(main())
