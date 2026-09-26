#!/usr/bin/env bash
#
# Build and run every waveform demo, then regenerate the GTKWave
# save files. Outputs land in waves/.

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${REPO_ROOT}"

DEMOS=(
    01_forwarding_chain
    02_load_use_stall
    03_branch_flush
    04_jal_jalr_call
    05_store_forwarding
    06_timer_interrupt
    07_sched_preempt
)

failures=0

for demo in "${DEMOS[@]}"; do
    ./scripts/run_waveform.sh "${demo}" || failures=$((failures + 1))
done

if [ "${failures}" -ne 0 ]; then
    echo "FAIL: ${failures} waveform demo(s) failed"
    exit 1
fi

python3 tests/waveforms/gen_gtkw.py

echo "PASS: all waveform demos generated in waves/"
