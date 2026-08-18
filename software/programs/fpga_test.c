#include "soc.h"
#include "uart.h"

int main(void)
{
    uart_puts("Hello from RV32I FPGA!\n");

    while (1) {
    }
}