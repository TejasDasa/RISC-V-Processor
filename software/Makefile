.DEFAULT_GOAL := all

PROGRAM ?= simple

BUILD_DIR := build
PROGRAM_DIR ?= programs
RUNTIME_DIR := runtime

CC := riscv64-unknown-elf-gcc
OBJCOPY := riscv64-unknown-elf-objcopy
OBJDUMP := riscv64-unknown-elf-objdump

ARCH_FLAGS := -march=rv32i_zicsr -mabi=ilp32

RUNTIME_SOURCES := \
	$(RUNTIME_DIR)/uart.c \
	$(RUNTIME_DIR)/timer.c \
	$(RUNTIME_DIR)/trap.c \
	$(RUNTIME_DIR)/trap_entry.S \
	$(RUNTIME_DIR)/task.c \
	$(RUNTIME_DIR)/context_start.S \
	$(RUNTIME_DIR)/context_switch.S \
	$(RUNTIME_DIR)/context_start_preemptive.S

INCLUDE_FLAGS := \
	-I$(RUNTIME_DIR)

CFLAGS := $(ARCH_FLAGS) \
          -O0 \
          -ffreestanding \
          -fno-builtin \
          -Wall \
          -Wextra \
          $(INCLUDE_FLAGS)

LDFLAGS := $(ARCH_FLAGS) \
           -nostdlib \
           -nostartfiles \
           -T linker.ld

ELF := $(BUILD_DIR)/$(PROGRAM).elf
DUMP := $(BUILD_DIR)/$(PROGRAM).dump

IMEM_BIN := $(BUILD_DIR)/$(PROGRAM)_imem.bin
IMEM_HEX := $(BUILD_DIR)/$(PROGRAM)_imem.hex

DMEM_BIN := $(BUILD_DIR)/$(PROGRAM)_dmem.bin
DMEM_HEX := $(BUILD_DIR)/$(PROGRAM)_dmem.hex

C_SOURCE := $(PROGRAM_DIR)/$(PROGRAM).c
S_SOURCE := $(PROGRAM_DIR)/$(PROGRAM).S

all: $(IMEM_HEX) $(DMEM_HEX) $(DUMP)

$(BUILD_DIR)/%.elf: $(PROGRAM_DIR)/%.c $(RUNTIME_SOURCES) crt0.S linker.ld
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(LDFLAGS) \
		crt0.S \
		$< \
		$(RUNTIME_SOURCES) \
		-o $@

$(BUILD_DIR)/%.elf: $(PROGRAM_DIR)/%.S linker.ld
	@mkdir -p $(BUILD_DIR)
	$(CC) $(ARCH_FLAGS) \
		-nostdlib \
		-nostartfiles \
		-T linker.ld \
		$< \
		-o $@

$(IMEM_BIN): $(ELF)
	$(OBJCOPY) \
		-O binary \
		--only-section=.text \
		$(ELF) \
		$(IMEM_BIN)

$(IMEM_HEX): $(IMEM_BIN)
	python3 bin_to_hex.py $(IMEM_BIN) $(IMEM_HEX)

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
		python3 bin_to_hex.py $(DMEM_BIN) $(DMEM_HEX); \
	else \
		echo "00000000" > $(DMEM_HEX); \
	fi

$(DUMP): $(ELF)
	$(OBJDUMP) -d $(ELF) > $(DUMP)

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean