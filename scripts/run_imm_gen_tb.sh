#!/usr/bin/env bash
set -e
rm -rf obj_dir

verilator --binary --timing -Wall -Wno-fatal --top-module imm_gen_tb \
  rtl/common/riscv_pkg.sv \
  rtl/core/imm_gen.sv \
  tests/unit/imm_gen_tb.sv

./obj_dir/Vimm_gen_tb