#!/usr/bin/env bash
set -e

echo "Running ALU tests..."
./scripts/run_alu_tb.sh

echo "Running regfile tests..."
./scripts/run_regfile_tb.sh

echo "Running imm_gen tests..."
./scripts/run_imm_gen_tb.sh

echo "PASS: all tests passed"