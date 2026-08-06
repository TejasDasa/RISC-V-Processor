#include "timer.h"
#include "uart.h"

int main(void)
{
    uart_puts("Start\n");

    uint32_t start = timer_read();

    while ((timer_read() - start) < 500)
        ;

    uart_puts("Done\n");
}