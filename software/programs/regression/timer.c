#include <stdint.h>

#include "timer.h"
#include "soc.h"

int main(void)
{
    timer_set_compare(100u);

    if (timer_get_compare() != 100u) {
        return 1;
    }

    timer_set_control(TIMER_ENABLE_MASK);

    if (timer_get_control() != TIMER_ENABLE_MASK) {
        return 2;
    }

    uint32_t start = timer_read();

    while ((timer_read() - start) < 25u) {
    }

    timer_disable();

    uint32_t stopped = timer_read();

    /*
     * Burn CPU cycles while the timer is disabled.
     */
    for (volatile uint32_t i = 0; i < 20u; i++) {
    }

    if (timer_read() != stopped) {
        return 3;
    }

    return 0;
}