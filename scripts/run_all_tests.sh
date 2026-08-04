#!/usr/bin/env bash

mkdir -p logs

failures=0
failed_tests=()

run_test() {
    local test_name="$1"
    local test_script="$2"
    local log_file="logs/${test_name}.log"
    local exit_code

    echo "Running ${test_name}..."

    "${test_script}" > "${log_file}" 2>&1
    exit_code=$?

    if [ "${exit_code}" -eq 0 ]; then
        echo "  PASS: ${test_name}"
    else
        echo "  FAIL: ${test_name}"
        failures=$((failures + 1))
        failed_tests+=("${test_name}")

        echo "  Last 20 lines from ${log_file}:"
        tail -n 20 "${log_file}"
        echo ""
    fi
}

run_test "alu_tb" "./scripts/run_alu_tb.sh"
run_test "regfile_tb" "./scripts/run_regfile_tb.sh"
run_test "imm_gen_tb" "./scripts/run_imm_gen_tb.sh"
run_test "branch_unit_tb.sv" "./scripts/run_branch_unit_tb.sh"
run_test "decoder_tb.sv" "./scripts/run_decoder_tb.sh"
run_test "pc_tb.sv" "./scripts/run_pc_tb.sh"
run_test "imem_tb.sv" "./scripts/run_imem_tb.sh"
run_test "dmem_tb.sv" "./scripts/run_dmem_tb.sh"
run_test "uart_tx_tb.sv" "./scripts/run_uart_tx_tb.sh"
run_test "bus_tb.sv" "./scripts/run_bus_tb.sh"
run_test "soc_tb.sv" "./scripts/run_soc_tb.sh"

echo ""
echo "=============================="
echo "Test Summary"
echo "=============================="

if [ "${failures}" -eq 0 ]; then
    echo "PASS: all tests passed"
    exit 0
else
    echo "FAIL: ${failures} test(s) failed"
    echo ""

    echo "Failed tests:"
    for test in "${failed_tests[@]}"; do
        echo "  - ${test}   log: logs/${test}.log"
    done

    exit 1
fi