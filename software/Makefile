TOOLCHAIN := riscv64-unknown-elf
ARCH_FLAGS := -march=rv32i -mabi=ilp32
BUILD_DIR := build
PROGRAM_DIR := programs

PROGRAM := add

ELF := $(BUILD_DIR)/$(PROGRAM).elf
BIN := $(BUILD_DIR)/$(PROGRAM).bin
HEX := $(BUILD_DIR)/$(PROGRAM).hex
DUMP := $(BUILD_DIR)/$(PROGRAM).dump

.PHONY: all clean

all: $(HEX) $(DUMP)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(ELF): $(PROGRAM_DIR)/$(PROGRAM).S linker.ld | $(BUILD_DIR)
	$(TOOLCHAIN)-gcc \
		$(ARCH_FLAGS) \
		-nostdlib \
		-nostartfiles \
		-T linker.ld \
		$< \
		-o $@

$(BIN): $(ELF)
	$(TOOLCHAIN)-objcopy -O binary $< $@

$(HEX): $(BIN) bin_to_hex.py
	python3 bin_to_hex.py $< $@

$(DUMP): $(ELF)
	$(TOOLCHAIN)-objdump -d -M no-aliases $< > $@

clean:
	rm -rf $(BUILD_DIR)