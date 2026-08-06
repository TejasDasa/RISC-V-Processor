#include <stdint.h>

#include "soc.h"
#include "timer.h"

#define TIMER_COUNT \
    (*(volatile uint32_t *)TIMER_COUNT_ADDR)

uint32_t timer_read(void)
{
    return TIMER_COUNT;
}