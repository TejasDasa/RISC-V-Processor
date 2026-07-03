#!/usr/bin/env bash
set -e
rm -rf obj_dir

verilator --binary --timing -Wall -Wno-fatal --top-module branch_unit_tb   rtl/common/riscv_pkg.sv   rtl/core/branch_unit.sv   tests/unit/branch_unit_tb.sv

./obj_dir/Vbranch_unit_tb