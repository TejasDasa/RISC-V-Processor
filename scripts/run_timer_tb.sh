#!/usr/bin/env bash
set -e

rm -rf obj_dir
mkdir -p logs

verilator \
  --binary \
  --timing \
  -Wall \
  -Wno-fatal \
  --top-module timer_tb \
  rtl/soc/timer.sv \
  tests/unit/timer_tb.sv

./obj_dir/Vtimer_tb | tee logs/timer_tb.log