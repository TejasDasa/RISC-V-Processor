#!/usr/bin/env bash
set -e
rm -rf obj_dir

verilator --binary --timing -Wall --top-module alu_tb \
  rtl/common/riscv_pkg.sv \
  rtl/core/alu.sv \
  tests/unit/alu_tb.sv

./obj_dir/Valu_tb