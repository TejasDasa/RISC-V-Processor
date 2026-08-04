#include <stdint.h>

/* .data: initialized writable globals */
uint32_t initialized_word = 17;
uint8_t initialized_byte = 0xA5;
uint16_t initialized_half = 0x1234;

/* .bss: zero-initialized globals */
uint32_t zero_word;
uint8_t zero_byte;
uint16_t zero_half;

/* .rodata: read-only data */
static const uint32_t constants[3] = {
    3,
    5,
    7
};

static const char message[] = "Hi";

static uint32_t add_values(uint32_t a, uint32_t b)
{
    /* Forces a normal function call and stack-frame activity at -O0. */
    volatile uint32_t local_sum = a + b;
    return local_sum;
}

int main(void)
{
    /* Stack locals */
    volatile uint32_t local_word = 20;
    volatile uint16_t local_half = 0x4567;
    volatile uint8_t local_byte = 0x81;

    /* Verify .data */
    uint32_t data_sum =
        initialized_word +
        initialized_byte +
        initialized_half;

    /* Verify .bss was cleared before main */
    uint32_t bss_sum =
        zero_word +
        zero_byte +
        zero_half;

    /* Exercise stores of every width into writable globals */
    zero_word = 0x11223344u;
    zero_half = 0xBEEFu;
    zero_byte = 0x7Au;

    /* Exercise loads of every width */
    uint32_t loaded_word = zero_word;
    uint32_t loaded_half = zero_half;
    uint32_t loaded_byte = zero_byte;

    /* Verify .rodata word and byte accesses */
    uint32_t rodata_sum =
        constants[0] +
        constants[1] +
        constants[2] +
        (uint8_t)message[0] +
        (uint8_t)message[1];

    uint32_t stack_sum =
        local_word +
        local_half +
        local_byte;

    uint32_t function_sum =
        add_values(loaded_half, loaded_byte);

    /*
     * Return a compact checksum.
     *
     * data_sum:
     *   17 + 0xA5 + 0x1234 = 4842
     *
     * bss_sum:
     *   0
     *
     * loaded low values:
     *   loaded_word & 0xFF = 0x44 = 68
     *   loaded_half        = 0xBEEF = 48879
     *   loaded_byte        = 0x7A = 122
     *
     * rodata_sum:
     *   3 + 5 + 7 + 'H' + 'i'
     *   = 15 + 72 + 105 = 192
     *
     * stack_sum:
     *   20 + 0x4567 + 0x81
     *   = 20 + 17767 + 129 = 17916
     *
     * function_sum:
     *   0xBEEF + 0x7A = 49001
     *
     * total:
     *   4842 + 0 + 68 + 48879 + 122
     *   + 192 + 17916 + 49001
     *   = 121020
     */
    return data_sum
         + bss_sum
         + (loaded_word & 0xFFu)
         + loaded_half
         + loaded_byte
         + rodata_sum
         + stack_sum
         + function_sum;
}