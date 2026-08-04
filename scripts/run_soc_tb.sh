#!/usr/bin/env bash
set -e

rm -rf obj_dir
mkdir -p logs

verilator \
  --binary \
  --timing \
  -Wall \
  -Wno-fatal \
  --top-module soc_tb \
  rtl/common/riscv_pkg.sv \
  rtl/core/pc.sv \
  rtl/core/imem.sv \
  rtl/core/decoder.sv \
  rtl/core/regfile.sv \
  rtl/core/imm_gen.sv \
  rtl/core/alu.sv \
  rtl/core/branch_unit.sv \
  rtl/core/dmem.sv \
  rtl/core/core.sv \
  rtl/soc/bus.sv \
  rtl/soc/soc.sv \
  tests/integration/soc_tb.sv

./obj_dir/Vsoc_tb | tee logs/soc_tb.log