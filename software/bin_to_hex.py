#!/usr/bin/env python3

from pathlib import Path
import sys


def main() -> None:
    if len(sys.argv) != 3:
        print("Usage: bin_to_hex.py <input.bin> <output.hex>")
        raise SystemExit(1)

    input_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])

    data = input_path.read_bytes()

    if len(data) % 4 != 0:
        raise ValueError(
            f"Binary size must be a multiple of 4 bytes, got {len(data)}"
        )

    words = []

    for offset in range(0, len(data), 4):
        word_bytes = data[offset : offset + 4]

        # RISC-V is little-endian, so the lowest-addressed byte is
        # the least significant byte of the 32-bit instruction.
        word = int.from_bytes(word_bytes, byteorder="little")

        words.append(f"{word:08x}")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(words) + "\n")

    print(f"Wrote {len(words)} words to {output_path}")


if __name__ == "__main__":
    main()