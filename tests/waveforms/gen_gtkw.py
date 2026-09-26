#!/usr/bin/env python3
"""
Generate the GTKWave save files (tests/waveforms/gtkw/<demo>.gtkw).

Each demo lists its signal groups below. Signal widths are read from
the demo's VCD, so run the waveforms first:

    ./scripts/run_all_waveforms.sh
    python3 tests/waveforms/gen_gtkw.py

Open a demo with:

    gtkwave tests/waveforms/gtkw/01_forwarding_chain.gtkw
"""

from __future__ import annotations

from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
SCOPE = "wave_tb.cpu"

# GTKWave trace flags
COMMENT = "@200"
BIN     = "@28"
HEX     = "@22"
DEC     = "@24"
ASCII   = "@820"

STAGES = ["if_asm", "id_asm", "ex_asm", "mem_asm", "wb_asm"]
WB     = ["wb_reg_write_en", "wb_rd_addr", "wb_data"]

DEMOS: dict[str, list[tuple[str, list[str]]]] = {
    "01_forwarding_chain": [
        ("Pipeline",   ["cycle", *STAGES]),
        ("Operands",   ["id_ex_rs1_addr", "id_ex_rs2_addr",
                        "ex_mem_rd_addr", "mem_wb_rd_addr"]),
        ("Forwarding", ["fwd_rs1_src", "fwd_rs2_src",
                        "id_ex_rs1_data", "id_ex_rs2_data",
                        "ex_rs1_forwarded", "ex_rs2_forwarded",
                        "ex_alu_result", "load_use_hazard"]),
        ("Writeback",  WB),
    ],
    "02_load_use_stall": [
        ("Pipeline",   ["cycle", *STAGES]),
        ("Hazard",     ["load_use_hazard", "pc_we", "pc_current",
                        "if_id_pc", "if_id_instr", "id_ex_valid",
                        "id_ex_mem_read_en", "id_ex_rd_addr"]),
        ("Memory",     ["ex_mem_valid", "bus_read_en", "bus_addr",
                        "bus_read_data", "mem_wb_valid"]),
        ("Forwarding", ["fwd_rs1_src", "ex_rs1_forwarded"]),
        ("Writeback",  WB),
    ],
    "03_branch_flush": [
        ("Pipeline",   ["cycle", *STAGES]),
        ("Branch",     ["fwd_rs1_src", "fwd_rs2_src",
                        "ex_rs1_forwarded", "ex_rs2_forwarded",
                        "ex_branch_taken", "ex_take_branch",
                        "ex_redirect", "ex_redirect_pc"]),
        ("Flush",      ["pc_current", "if_id_valid", "id_ex_valid",
                        "ex_mem_valid", "mem_wb_valid"]),
        ("Writeback",  WB),
    ],
    "04_jal_jalr_call": [
        ("Pipeline",   ["cycle", *STAGES]),
        ("Control",    ["ex_take_jump", "ex_take_jalr", "ex_redirect",
                        "ex_redirect_pc", "pc_current"]),
        ("Link",       ["ex_rs1_forwarded", "x1_ra", "x10_a0"]),
        ("Writeback",  WB),
    ],
    "05_store_forwarding": [
        ("Pipeline",   ["cycle", *STAGES]),
        ("Operands",   ["fwd_rs1_src", "fwd_rs2_src",
                        "ex_rs1_forwarded", "ex_rs2_forwarded",
                        "ex_alu_result"]),
        ("Store",      ["ex_mem_rs2_data", "bus_addr", "bus_write_en",
                        "bus_write_data", "bus_byte_en"]),
        ("Load back",  ["bus_read_en", "bus_read_data"]),
        ("Writeback",  WB),
    ],
    "06_timer_interrupt": [
        ("Pipeline",   ["cycle", *STAGES, "pc_current"]),
        ("Timer",      ["timer_count", "timer_compare", "cpu_irq",
                        "timer_irq_pending"]),
        ("Enables",    ["global_irq_enable", "timer_irq_enable",
                        "mstatus"]),
        ("Trap entry", ["ex_irq", "trap_enter", "trap_cause",
                        "ex_redirect", "ex_redirect_pc", "mtvec",
                        "mepc", "mcause"]),
        ("Flush",      ["if_id_valid", "id_ex_valid", "ex_mem_valid",
                        "mem_wb_valid"]),
        ("Return",     ["ex_take_mret"]),
        ("Retire",     ["retire_valid", "retire_pc", "retire_interrupt",
                        "retire_cause", "x10_a0"]),
    ],
    "07_sched_preempt": [
        ("Task",       ["cycle", "gpio_out", "x2_sp", "pc_current",
                        "ex_asm"]),
        ("Timer",      ["timer_count", "timer_compare", "cpu_irq"]),
        ("Trap",       ["global_irq_enable", "ex_irq", "trap_enter",
                        "mepc", "mcause", "ex_take_mret",
                        "ex_redirect_pc"]),
        ("Context save / restore",
                       ["bus_write_en", "bus_read_en", "bus_addr",
                        "bus_write_data", "bus_read_data"]),
        ("Retire",     ["retire_interrupt", "retire_pc"]),
    ],
}


def signal_widths(vcd: Path) -> dict[str, int]:
    widths: dict[str, int] = {}
    scope: list[str] = []
    for line in vcd.read_text().splitlines():
        tok = line.split()
        if not tok:
            continue
        if tok[0] == "$scope":
            scope.append(tok[2])
        elif tok[0] == "$upscope":
            scope.pop()
        elif tok[0] == "$var" and scope and scope[-1] == "cpu":
            widths[tok[4]] = int(tok[2])
        elif tok[0] == "$enddefinitions":
            break
    return widths


def trace_flag(name: str, width: int) -> str:
    if name.endswith(("_asm", "_src")):
        return ASCII
    if width == 1:
        return BIN
    if name.endswith(("_addr", "cycle")) and "bus" not in name:
        return DEC
    return HEX


def write_gtkw(demo: str, groups: list[tuple[str, list[str]]]) -> None:
    vcd = REPO / "waves" / f"{demo}.vcd"
    if not vcd.exists():
        sys.exit(f"missing {vcd}: run ./scripts/run_waveform.sh {demo}")

    widths = signal_widths(vcd)

    lines = [
        f"[*] {demo} - generated by tests/waveforms/gen_gtkw.py",
        f'[dumpfile] "../../../waves/{demo}.vcd"',
        "[size] 1600 900",
        "[sst_width] 240",
        "[signals_width] 260",
        "[sst_expanded] 1",
        f"[treeopen] wave_tb.",
        f"[treeopen] {SCOPE}.",
        BIN,
        f"{SCOPE}.clk",
    ]

    for title, names in groups:
        lines += [COMMENT, f"-{title}"]
        for name in names:
            if name not in widths:
                sys.exit(f"{demo}: {name} not in {vcd.name}")
            w = widths[name]
            lines.append(trace_flag(name, w))
            lines.append(f"{SCOPE}.{name}" +
                         (f"[{w - 1}:0]" if w > 1 else ""))

    out = HERE / "gtkw" / f"{demo}.gtkw"
    out.parent.mkdir(exist_ok=True)
    out.write_text("\n".join(lines) + "\n")
    print(f"wrote {out.relative_to(REPO)}")


def main() -> None:
    for demo, groups in DEMOS.items():
        write_gtkw(demo, groups)


if __name__ == "__main__":
    main()
