#!/usr/bin/env bash
set -e

rm -rf obj_dir
mkdir -p logs

PROGRAM="${1:-add}"

IMEM_HEX_FILE="software/build/${PROGRAM}_imem.hex"
DMEM_HEX_FILE="software/build/${PROGRAM}_dmem.hex"
EXPECTED_FILE="${2:-software/programs/${PROGRAM}.expected}"
LOG_FILE="logs/${PROGRAM}.program.log"

if [ ! -f "${IMEM_HEX_FILE}" ]; then
    echo "ERROR: missing ${IMEM_HEX_FILE}"
    echo "Build it with: make -C software PROGRAM=${PROGRAM}"
    exit 1
fi

if [ ! -f "${DMEM_HEX_FILE}" ]; then
    echo "ERROR: missing ${DMEM_HEX_FILE}"
    echo "Build it with: make -C software PROGRAM=${PROGRAM}"
    exit 1
fi

if [ ! -f "${EXPECTED_FILE}" ]; then
    echo "ERROR: missing ${EXPECTED_FILE}"
    exit 1
fi

verilator \
  --binary \
  --timing \
  -GPROGRAM_HEX="\"${IMEM_HEX_FILE}\"" \
  -GPROGRAM_DMEM_HEX="\"${DMEM_HEX_FILE}\"" \
  -Wall \
  -Wno-fatal \
  --top-module program_tb \
  rtl/common/riscv_pkg.sv \
  rtl/common/soc_pkg.sv \
  rtl/core/pc.sv \
  rtl/core/imem.sv \
  rtl/core/decoder.sv \
  rtl/core/regfile.sv \
  rtl/core/imm_gen.sv \
  rtl/core/alu.sv \
  rtl/core/branch_unit.sv \
  rtl/core/dmem.sv \
  rtl/core/csr_file.sv \
  rtl/soc/uart_tx.sv \
  rtl/soc/timer.sv \
  rtl/soc/interrupt_controller.sv \
  rtl/soc/bus.sv \
  rtl/core/core.sv \
  rtl/soc/soc.sv \
  tests/integration/program_tb.sv

set +e

./obj_dir/Vprogram_tb > "${LOG_FILE}" 2>&1
sim_status=$?

python3 scripts/check_program_output.py \
    "${LOG_FILE}" \
    "${EXPECTED_FILE}"
check_status=$?

set -e

if [ "${sim_status}" -ne 0 ] || [ "${check_status}" -ne 0 ]; then
    echo "FAIL: ${PROGRAM}"
    echo "Simulation log: ${LOG_FILE}"
    exit 1
fi

echo "PASS: ${PROGRAM}"