#!/usr/bin/env bash
set -e

rm -rf obj_dir

verilator \
  --binary \
  --timing \
  -Wall \
  -Wno-fatal \
  --top-module uart_tx_tb \
  rtl/soc/uart_tx.sv \
  tests/unit/uart_tx_tb.sv

./obj_dir/Vuart_tx_tb