#include "timer.h"
#include "uart.h"
#include "soc.h"

int main(void)
{
    uart_puts("Timer start\n");

    timer_set_compare(100u);
    timer_set_control(TIMER_ENABLE_MASK);

    uint32_t start = timer_read();

    while ((timer_read() - start) < 100u) {
    }

    timer_disable();

    uart_puts("Timer done\n");

    return 0;
}