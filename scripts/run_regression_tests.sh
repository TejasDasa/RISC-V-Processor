#!/usr/bin/env bash

mkdir -p logs

failures=0
passed=0
failed_programs=()

PROGRAM_DIR="software/programs/regression"
MAKE_PROGRAM_DIR="programs/regression"

run_program() {
    local expected_file="$1"
    local program
    local source_file=""
    local log_file
    local exit_code

    program="$(basename "${expected_file}" .expected)"
    log_file="logs/${program}.regression.log"

    if [ -f "${PROGRAM_DIR}/${program}.c" ]; then
        source_file="${PROGRAM_DIR}/${program}.c"
    elif [ -f "${PROGRAM_DIR}/${program}.S" ]; then
        source_file="${PROGRAM_DIR}/${program}.S"
    else
        echo "  SKIP: ${program} has no .c or .S source"
        return
    fi

    echo "Running ${program} (${source_file})..."

    make -C software \
        PROGRAM_DIR="${MAKE_PROGRAM_DIR}" \
        PROGRAM="${program}" \
        > "${log_file}" 2>&1

    exit_code=$?

    if [ "${exit_code}" -eq 0 ]; then
        ./scripts/run_program_tb.sh "${program}" \
            "${PROGRAM_DIR}/${program}.expected" \
            >> "${log_file}" 2>&1
        exit_code=$?
    fi

    if [ "${exit_code}" -eq 0 ]; then
        echo "  PASS: ${program}"
        passed=$((passed + 1))
    else
        echo "  FAIL: ${program}"
        failures=$((failures + 1))
        failed_programs+=("${program}")

        echo "  Last 20 log lines:"
        tail -n 20 "${log_file}"
        echo ""
    fi
}

echo "=============================="
echo "Program Regression"
echo "=============================="
echo ""

shopt -s nullglob

expected_files=("${PROGRAM_DIR}"/*.expected)

if [ "${#expected_files[@]}" -eq 0 ]; then
    echo "ERROR: no .expected files found in ${PROGRAM_DIR}"
    exit 1
fi

for expected_file in "${expected_files[@]}"; do
    run_program "${expected_file}"
done

echo ""
echo "=============================="
echo "Regression Summary"
echo "=============================="
echo "Passed: ${passed}"
echo "Failed: ${failures}"

if [ "${failures}" -ne 0 ]; then
    echo ""
    echo "Failed programs:"

    for program in "${failed_programs[@]}"; do
        echo "  - ${program}"
        echo "    log: logs/${program}.regression.log"
    done

    exit 1
fi

echo ""
echo "PASS: all program regressions passed"