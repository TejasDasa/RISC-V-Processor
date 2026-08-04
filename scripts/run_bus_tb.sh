#!/usr/bin/env bash
set -e

rm -rf obj_dir
mkdir -p logs

verilator \
  --binary \
  --timing \
  -Wall \
  -Wno-fatal \
  --top-module bus_tb \
  rtl/core/dmem.sv \
  rtl/soc/bus.sv \
  tests/unit/bus_tb.sv

./obj_dir/Vbus_tb | tee logs/bus_tb.log