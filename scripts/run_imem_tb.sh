#!/usr/bin/env bash
set -e
rm -rf obj_dir

verilator --binary --timing -Wall -Wno-fatal --top-module imem_tb \
  rtl/core/imem.sv \
  tests/unit/imem_tb.sv

./obj_dir/Vimem_tb