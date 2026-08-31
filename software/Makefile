.DEFAULT_GOAL := all


# ============================================================
# Paths
# ============================================================

# This Makefile lives in software/
SOFTWARE_DIR := $(CURDIR)
REPO_ROOT    := $(abspath $(SOFTWARE_DIR)/..)

BUILD_DIR   := $(SOFTWARE_DIR)/build
RUNTIME_DIR := $(SOFTWARE_DIR)/runtime

PROGRAM ?= simple

# Normal programs live here.
PROGRAM_DIR ?= $(SOFTWARE_DIR)/programs

# Random verification programs are generated here.
RANDOM_DIR := $(REPO_ROOT)/tests/random/generated

RANDOM_REFERENCE := $(BUILD_DIR)/random_reference.log


# ============================================================
# Toolchain
# ============================================================

CC      := riscv64-unknown-elf-gcc
OBJCOPY := riscv64-unknown-elf-objcopy
OBJDUMP := riscv64-unknown-elf-objdump

ARCH_FLAGS := -march=rv32i_zicsr -mabi=ilp32

INCLUDE_FLAGS := \
	-I$(RUNTIME_DIR)

CFLAGS := \
	$(ARCH_FLAGS) \
	-O0 \
	-ffreestanding \
	-fno-builtin \
	-Wall \
	-Wextra \
	$(INCLUDE_FLAGS)

LDFLAGS := \
	$(ARCH_FLAGS) \
	-nostdlib \
	-nostartfiles \
	-T $(SOFTWARE_DIR)/linker.ld


# ============================================================
# Runtime
# ============================================================

RUNTIME_SOURCES := \
	$(RUNTIME_DIR)/uart.c \
	$(RUNTIME_DIR)/timer.c \
	$(RUNTIME_DIR)/trap.c \
	$(RUNTIME_DIR)/trap_entry.S \
	$(RUNTIME_DIR)/task.c \
	$(RUNTIME_DIR)/context_start.S \
	$(RUNTIME_DIR)/context_switch.S \
	$(RUNTIME_DIR)/context_start_preemptive.S


# ============================================================
# Program source selection
# ============================================================

C_SOURCE := $(PROGRAM_DIR)/$(PROGRAM).c
S_SOURCE := $(PROGRAM_DIR)/$(PROGRAM).S

PROGRAM_SOURCE := $(firstword \
	$(wildcard $(C_SOURCE)) \
	$(wildcard $(S_SOURCE)) \
)


# ============================================================
# Build outputs
# ============================================================

ELF := $(BUILD_DIR)/$(PROGRAM).elf

DUMP := $(BUILD_DIR)/$(PROGRAM).dump

IMEM_BIN := $(BUILD_DIR)/$(PROGRAM)_imem.bin
IMEM_HEX := $(BUILD_DIR)/$(PROGRAM)_imem.hex

DMEM_BIN := $(BUILD_DIR)/$(PROGRAM)_dmem.bin
DMEM_HEX := $(BUILD_DIR)/$(PROGRAM)_dmem.hex


# ============================================================
# Normal software build
# ============================================================

all: $(IMEM_HEX) $(DMEM_HEX) $(DUMP)


# ------------------------------------------------------------
# ELF
# ------------------------------------------------------------

$(ELF): $(PROGRAM_SOURCE) $(SOFTWARE_DIR)/linker.ld
	@if [ -z "$(PROGRAM_SOURCE)" ]; then \
		echo "ERROR: Could not find $(PROGRAM).c or $(PROGRAM).S in $(PROGRAM_DIR)"; \
		exit 1; \
	fi
	@mkdir -p $(BUILD_DIR)

ifeq ($(suffix $(PROGRAM_SOURCE)),.c)
	$(CC) $(CFLAGS) $(LDFLAGS) \
		$(SOFTWARE_DIR)/crt0.S \
		$(PROGRAM_SOURCE) \
		$(RUNTIME_SOURCES) \
		-o $(ELF)
else
	$(CC) $(ARCH_FLAGS) \
		-nostdlib \
		-nostartfiles \
		-T $(SOFTWARE_DIR)/linker.ld \
		$(PROGRAM_SOURCE) \
		-o $(ELF)
endif


# ------------------------------------------------------------
# IMEM
# ------------------------------------------------------------

$(IMEM_BIN): $(ELF)
	$(OBJCOPY) \
		-O binary \
		--only-section=.text \
		$(ELF) \
		$(IMEM_BIN)

$(IMEM_HEX): $(IMEM_BIN)
	python3 $(SOFTWARE_DIR)/bin_to_hex.py \
		$(IMEM_BIN) \
		$(IMEM_HEX)


# ------------------------------------------------------------
# DMEM
# ------------------------------------------------------------

$(DMEM_BIN): $(ELF)
	$(OBJCOPY) \
		-O binary \
		--only-section=.rodata \
		--only-section=.srodata \
		--only-section=.data \
		--only-section=.sdata \
		$(ELF) \
		$(DMEM_BIN)

$(DMEM_HEX): $(DMEM_BIN)
	@if [ -s "$(DMEM_BIN)" ]; then \
		python3 $(SOFTWARE_DIR)/bin_to_hex.py \
			$(DMEM_BIN) \
			$(DMEM_HEX); \
	else \
		echo "00000000" > $(DMEM_HEX); \
	fi


# ------------------------------------------------------------
# Disassembly
# ------------------------------------------------------------

$(DUMP): $(ELF)
	$(OBJDUMP) -d $(ELF) > $(DUMP)


# ============================================================
# Verilator simulation
# ============================================================

TRACE_RETIRE ?= 0

VERILATOR_DEFINES :=

ifeq ($(TRACE_RETIRE),1)
VERILATOR_DEFINES += -DTRACE_RETIRE
endif


SIM_BUILD_DIR := $(REPO_ROOT)/obj_dir_program
SIM_BINARY    := $(SIM_BUILD_DIR)/Vprogram_tb
SIM_LOG       := $(BUILD_DIR)/$(PROGRAM)_simulation.log


VERILATOR_SOURCES := \
	$(REPO_ROOT)/rtl/common/riscv_pkg.sv \
	$(REPO_ROOT)/rtl/common/soc_pkg.sv \
	$(REPO_ROOT)/rtl/core/pc.sv \
	$(REPO_ROOT)/rtl/core/imem.sv \
	$(REPO_ROOT)/rtl/core/decoder.sv \
	$(REPO_ROOT)/rtl/core/regfile.sv \
	$(REPO_ROOT)/rtl/core/imm_gen.sv \
	$(REPO_ROOT)/rtl/core/alu.sv \
	$(REPO_ROOT)/rtl/core/branch_unit.sv \
	$(REPO_ROOT)/rtl/core/dmem.sv \
	$(REPO_ROOT)/rtl/core/csr_file.sv \
	$(REPO_ROOT)/rtl/soc/uart_tx.sv \
	$(REPO_ROOT)/rtl/soc/timer.sv \
	$(REPO_ROOT)/rtl/soc/gpio.sv \
	$(REPO_ROOT)/rtl/soc/interrupt_controller.sv \
	$(REPO_ROOT)/rtl/soc/bus.sv \
	$(REPO_ROOT)/rtl/core/core.sv \
	$(REPO_ROOT)/rtl/soc/soc.sv \
	$(REPO_ROOT)/tests/uvm_like/cpu_monitor.sv \
	$(REPO_ROOT)/tests/uvm_like/cpu_assertions.sv \
	$(REPO_ROOT)/tests/uvm_like/cpu_coverage.sv \
	$(REPO_ROOT)/tests/integration/program_tb.sv


.PHONY: sim
sim: all
	@echo "============================================================"
	@echo " Building simulation for $(PROGRAM)"
	@echo " IMEM: $(IMEM_HEX)"
	@echo " DMEM: $(DMEM_HEX)"
	@echo "============================================================"

	rm -rf $(SIM_BUILD_DIR)

	verilator \
		--binary \
		--timing \
		--Mdir $(SIM_BUILD_DIR) \
		-GPROGRAM_HEX="\"$(IMEM_HEX)\"" \
		-GPROGRAM_DMEM_HEX="\"$(DMEM_HEX)\"" \
		-Wall \
		-Wno-fatal \
		$(VERILATOR_DEFINES) \
		--top-module program_tb \
		$(VERILATOR_SOURCES)

	@echo ""
	@echo "============================================================"
	@echo " Running $(PROGRAM)"
	@echo "============================================================"

	$(SIM_BINARY) | tee $(SIM_LOG)

	@echo ""
	@echo "Simulation log: $(SIM_LOG)"


# ============================================================
# Randomized verification
# ============================================================

SEED  ?= 1
COUNT ?= 100


.PHONY: generate-random
generate-random:
	python3 $(REPO_ROOT)/tests/random/gen_program.py \
		$(SEED) \
		$(COUNT)


.PHONY: random-sim
random-sim: generate-random
	@mkdir -p $(BUILD_DIR)
	@echo "============================================================"
	@echo " Generating reference state"
	@echo "============================================================"

	python3 $(REPO_ROOT)/tests/random/reference_model.py \
		$(RANDOM_DIR)/random_test.S \
		> $(RANDOM_REFERENCE)

	$(MAKE) \
		PROGRAM=random_test \
		PROGRAM_DIR=$(RANDOM_DIR) \
		TRACE_RETIRE=1 \
		sim

	@echo ""
	@echo "============================================================"
	@echo " Comparing RTL against reference model"
	@echo "============================================================"

	python3 $(REPO_ROOT)/tests/random/compare_results.py \
		$(RANDOM_REFERENCE) \
		$(BUILD_DIR)/random_test_simulation.log


# ============================================================
# Utility
# ============================================================

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(SIM_BUILD_DIR)


.PHONY: all clean sim generate-random random-sim