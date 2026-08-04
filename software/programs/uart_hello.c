#include <stdint.h>

#define UART_TX_DATA (*(volatile uint8_t *)0x10000000u)

#define UART_STATUS (*(volatile uint32_t *)0x10000004u)

#define UART_BUSY_MASK 1u

static void uart_putc(char c)
{
    while ((UART_STATUS & UART_BUSY_MASK) != 0u) {
    }

    UART_TX_DATA = (uint8_t)c;
}

static void uart_puts(const char *text)
{
    while (*text != '\0') {
        uart_putc(*text);
        text++;
    }
}

int main(void)
{
    uart_puts("Hello from RISC-V!\n");
    return 0;
}