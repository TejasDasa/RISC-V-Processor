#include <stdint.h>

volatile uint32_t word_value;
volatile uint16_t half_values[2];
volatile uint8_t byte_value;

int main(void)
{
    word_value = 0x11223344u;
    half_values[0] = 0x1234u;
    half_values[1] = 0xBEEFu;
    byte_value = 0x7Au;

    return (int)(
        (word_value & 0xFFu) +
        half_values[0] +
        half_values[1] +
        byte_value
    );
}