#!/usr/bin/env bash
set -e

rm -rf obj_dir

verilator --binary --timing -Wall -Wno-fatal --top-module core_tb \
  rtl/core/pc.sv \
  rtl/core/imem.sv \
  rtl/core/core.sv \
  tests/unit/core_tb.sv

./obj_dir/Vcore_tb