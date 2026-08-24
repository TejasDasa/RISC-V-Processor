#!/usr/bin/env bash
set -e

rm -rf obj_dir
mkdir -p logs

LOG_FILE="logs/soc_tb.log"

verilator \
  --binary \
  --timing \
  -Wall \
  -Wno-fatal \
  --top-module soc_tb \
  rtl/common/riscv_pkg.sv \
  rtl/common/soc_pkg.sv \
  rtl/core/pc.sv \
  rtl/core/imem.sv \
  rtl/core/decoder.sv \
  rtl/core/regfile.sv \
  rtl/core/imm_gen.sv \
  rtl/core/alu.sv \
  rtl/core/branch_unit.sv \
  rtl/soc/uart_tx.sv \
  rtl/soc/timer.sv \
  rtl/soc/interrupt_controller.sv \
  rtl/core/dmem.sv \
  rtl/core/core.sv \
  rtl/soc/bus.sv \
  rtl/soc/soc.sv \
  tests/integration/soc_tb.sv

set +e
./obj_dir/Vsoc_tb | tee "${LOG_FILE}"
sim_status=${PIPESTATUS[0]}
set -e

if [ "${sim_status}" -ne 0 ]; then
    echo "FAIL: soc_tb"
    echo "Log: ${LOG_FILE}"
    exit "${sim_status}"
fi

echo "PASS: soc_tb"