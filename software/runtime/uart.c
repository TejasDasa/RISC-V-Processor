#include <stdint.h>

#include "soc.h"
#include "uart.h"

#define UART_TX_REG \
    (*(volatile uint8_t *)UART_TX_ADDR)

#define UART_STATUS_REG \
    (*(volatile uint32_t *)UART_STATUS_ADDR)

void uart_putc(char c)
{
    while ((UART_STATUS_REG & UART_BUSY_MASK) != 0u) {
        // Wait until the transmitter is ready.
    }

    UART_TX_REG = (uint8_t)c;
}

void uart_puts(const char *text)
{
    while (*text != '\0') {
        uart_putc(*text);
        text++;
    }
}