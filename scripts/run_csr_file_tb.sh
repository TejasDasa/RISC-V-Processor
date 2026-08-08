#!/usr/bin/env bash
set -e

rm -rf obj_dir
mkdir -p logs

verilator \
  --binary \
  --timing \
  -Wall \
  -Wno-fatal \
  --top-module csr_file_tb \
  rtl/core/csr_file.sv \
  tests/unit/csr_file_tb.sv

./obj_dir/Vcsr_file_tb | tee logs/csr_file_tb.log