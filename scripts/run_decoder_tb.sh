#!/usr/bin/env bash
set -e
rm -rf obj_dir

verilator --binary --timing -Wall -Wno-fatal --top-module decoder_tb \
    rtl/common/riscv_pkg.sv \
    rtl/core/decoder.sv \
    tests/unit/decoder_tb.sv

./obj_dir/Vdecoder_tb