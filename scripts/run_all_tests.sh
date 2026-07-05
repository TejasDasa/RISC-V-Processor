#!/usr/bin/env bash

mkdir -p logs

failures=0
failed_tests=()

run_test() {
    test_name="$1"
    test_script="$2"
    log_file="logs/${test_name}.log"

    echo "Running ${test_name}..."

    "${test_script}" > "${log_file}" 2>&1
    exit_code=$?

    if [ "${exit_code}" -eq 0 ] && ! grep -qi "error\|fatal\|fail" "${log_file}"; then
        echo "  PASS: ${test_name}"
    else
        echo "  FAIL: ${test_name}"
        failures=$((failures + 1))
        failed_tests+=("${test_name}")

        echo "  Relevant lines from ${log_file}:"
        grep -in "error\|fatal\|fail" "${log_file}" | tail -n 20 || tail -n 20 "${log_file}"
        echo ""
    fi
}

run_test "alu_tb" "./scripts/run_alu_tb.sh"
run_test "regfile_tb" "./scripts/run_regfile_tb.sh"
run_test "imm_gen_tb" "./scripts/run_imm_gen_tb.sh"
run_test "branch_unit_tb.sv" "./scripts/run_branch_unit_tb.sh"
run_test "decoder_tb.sv" "./scripts/run_decoder_tb.sh"

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