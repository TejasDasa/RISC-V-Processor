#!/usr/bin/env bash
set -e
rm -rf obj_dir

verilator --binary --timing -Wall --top-module pc_tb \
  rtl/core/pc.sv \
  tests/unit/pc_tb.sv

./obj_dir/Vpc_tb