PROGRAM ?= simple

BUILD_DIR := build
PROGRAM_DIR := programs

.DEFAULT_GOAL := all

CC := riscv64-unknown-elf-gcc
OBJCOPY := riscv64-unknown-elf-objcopy
OBJDUMP := riscv64-unknown-elf-objdump

ARCH_FLAGS := -march=rv32i -mabi=ilp32

CFLAGS := $(ARCH_FLAGS) \
          -O0 \
          -ffreestanding \
          -fno-builtin \
          -Wall \
          -Wextra

LDFLAGS := $(ARCH_FLAGS) \
           -nostdlib \
           -nostartfiles \
           -T linker.ld

ELF := $(BUILD_DIR)/$(PROGRAM).elf
BIN := $(BUILD_DIR)/$(PROGRAM).bin
HEX := $(BUILD_DIR)/$(PROGRAM).hex
DUMP := $(BUILD_DIR)/$(PROGRAM).dump

C_SOURCE := $(PROGRAM_DIR)/$(PROGRAM).c
S_SOURCE := $(PROGRAM_DIR)/$(PROGRAM).S

$(ELF):
	@mkdir -p $(BUILD_DIR)
	@if [ -f "$(C_SOURCE)" ]; then \
		echo "Building C program: $(C_SOURCE)"; \
		$(CC) $(CFLAGS) $(LDFLAGS) \
			crt0.S \
			$(C_SOURCE) \
			-o $(ELF); \
	elif [ -f "$(S_SOURCE)" ]; then \
		echo "Building assembly program: $(S_SOURCE)"; \
		$(CC) $(ARCH_FLAGS) \
			-nostdlib \
			-nostartfiles \
			-T linker.ld \
			$(S_SOURCE) \
			-o $(ELF); \
	else \
		echo "ERROR: no source found for $(PROGRAM)"; \
		exit 1; \
	fi

$(BIN): $(ELF)
	$(OBJCOPY) -O binary $(ELF) $(BIN)

$(HEX): $(BIN)
	python3 bin_to_hex.py $(BIN) $(HEX)

$(DUMP): $(ELF)
	$(OBJDUMP) -d $(ELF) > $(DUMP)

all: $(HEX) $(DUMP)

clean:
	rm -rf $(BUILD_DIR)