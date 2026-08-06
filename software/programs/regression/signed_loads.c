#include <stdint.h>

volatile int8_t signed_byte = -127;
volatile int16_t signed_half = -1234;

int main(void)
{
    return signed_byte + signed_half;
}