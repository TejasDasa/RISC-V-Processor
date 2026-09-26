#!/usr/bin/env bash
#
# Build and run one waveform demo:
#
#   ./scripts/run_waveform.sh 01_forwarding_chain
#
# Produces:
#   waves/<demo>.vcd                  waveform (probe signals only)
#   logs/<demo>.wave.log              simulation log with PIPE table
#
# View with:
#   gtkwave waves/<demo>.vcd tests/waveforms/gtkw/<demo>.gtkw
#
# Set WAVE_FORMAT=fst for a compressed FST file instead (needs the
# zlib headers: sudo apt install zlib1g-dev).

set -e

DEMO="${1:?usage: $0 <demo-name>}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${REPO_ROOT}"

WAVE_DIR="tests/waveforms"
PROGRAM_DIR="${REPO_ROOT}/${WAVE_DIR}/programs"

IMEM_HEX="software/build/${DEMO}_imem.hex"
DMEM_HEX="software/build/${DEMO}_dmem.hex"
WAVE_FORMAT="${WAVE_FORMAT:-vcd}"
case "${WAVE_FORMAT}" in
    vcd) TRACE_FLAG="--trace" ;;
    fst) TRACE_FLAG="--trace-fst" ;;
    *)   echo "WAVE_FORMAT must be vcd or fst"; exit 1 ;;
esac

WAVE_FILE="waves/${DEMO}.${WAVE_FORMAT}"
LOG_FILE="logs/${DEMO}.wave.log"
MDIR="obj_dir_wave"

mkdir -p waves logs

make -s -C software PROGRAM_DIR="${PROGRAM_DIR}" PROGRAM="${DEMO}" \
    > "logs/${DEMO}.wave.make.log" 2>&1 || {
    echo "FAIL: software build for ${DEMO} (logs/${DEMO}.wave.make.log)"
    tail -20 "logs/${DEMO}.wave.make.log"
    exit 1
}

# Optional per-demo testbench parameters, e.g. -GDUMP_START_ON_MRET=1
EXTRA_FLAGS=()
if [ -f "${WAVE_DIR}/programs/${DEMO}.flags" ]; then
    read -r -a EXTRA_FLAGS < "${WAVE_DIR}/programs/${DEMO}.flags"
fi

rm -rf "${MDIR}"

verilator \
  --binary \
  --timing \
  --assert \
  "${TRACE_FLAG}" \
  --Mdir "${MDIR}" \
  -Wall \
  -Wno-fatal \
  -GPROGRAM_HEX="\"${IMEM_HEX}\"" \
  -GPROGRAM_DMEM_HEX="\"${DMEM_HEX}\"" \
  -GWAVE_FILE="\"${WAVE_FILE}\"" \
  "${EXTRA_FLAGS[@]}" \
  --top-module wave_tb \
  "${WAVE_DIR}/waves.vlt" \
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
  rtl/soc/gpio.sv \
  rtl/soc/interrupt_controller.sv \
  rtl/soc/bus.sv \
  rtl/core/core.sv \
  rtl/soc/soc.sv \
  tests/uvm_like/cpu_assertions.sv \
  "${WAVE_DIR}/rv_disasm_pkg.sv" \
  "${WAVE_DIR}/wave_probe.sv" \
  "${WAVE_DIR}/wave_tb.sv" \
  > "logs/${DEMO}.wave.build.log" 2>&1 || {
    echo "FAIL: verilator build for ${DEMO} (logs/${DEMO}.wave.build.log)"
    grep -E "%Error" "logs/${DEMO}.wave.build.log" | head -20
    exit 1
  }

set +e
"./${MDIR}/Vwave_tb" > "${LOG_FILE}" 2>&1
sim_status=$?

python3 scripts/check_program_output.py \
    "${LOG_FILE}" \
    "${WAVE_DIR}/programs/${DEMO}.expected" \
    > "logs/${DEMO}.wave.check.log"
check_status=$?
set -e

if [ "${sim_status}" -ne 0 ] || [ "${check_status}" -ne 0 ] ||
   grep -q "Assertion failed\|did not halt" "${LOG_FILE}"; then
    echo "FAIL: ${DEMO}"
    grep -E "^FAIL|Assertion failed|did not halt" \
        "${LOG_FILE}" "logs/${DEMO}.wave.check.log" | head -20
    exit 1
fi

echo "PASS: ${DEMO} -> ${WAVE_FILE} ($(grep -o '([0-9]* cycles)' "${LOG_FILE}"))"
