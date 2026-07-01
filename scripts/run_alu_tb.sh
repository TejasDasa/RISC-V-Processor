#!/usr/bin/env bash
set -e

verilator --binary --timing -Wall --top-module alu_tb \
  rtl/common/riscv_pkg.sv \
  rtl/core/alu.sv \
  tests/unit/alu_tb.sv

./obj_dir/Valu_tb