#!/usr/bin/env bash
set -e

verilator --binary --timing -Wall --top-module regfile_tb \
  rtl/core/regfile.sv \
  tests/unit/regfile_tb.sv

./obj_dir/Vregfile_tb