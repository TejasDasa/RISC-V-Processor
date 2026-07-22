#!/usr/bin/env bash
set -e

rm -rf obj_dir

verilator --binary --timing -Wall -Wno-fatal --top-module core_tb \
  rtl/common/riscv_pkg.sv \
  rtl/core/pc.sv \
  rtl/mem/imem.sv \
  rtl/core/decoder.sv \
  rtl/core/regfile.sv \
  rtl/core/imm_gen.sv \
  rtl/core/alu.sv \
  rtl/core/branch_unit.sv \
  rtl/mem/dmem.sv \
  rtl/core/core.sv \
  tests/unit/core_tb.sv

./obj_dir/Vcore_tb