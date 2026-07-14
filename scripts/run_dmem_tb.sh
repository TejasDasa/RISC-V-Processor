#!/usr/bin/env bash
set -e

rm -rf obj_dir

verilator --binary --timing -Wall -Wno-fatal --top-module dmem_tb \
  rtl/core/dmem.sv \
  tests/unit/dmem_tb.sv

./obj_dir/Vdmem_tb