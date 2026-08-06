#include <stdint.h>

#include "soc.h"
#include "timer.h"

#define TIMER_COUNT_REG \
    (*(volatile uint32_t *)TIMER_COUNT_ADDR)

#define TIMER_COMPARE_REG \
    (*(volatile uint32_t *)TIMER_COMPARE_ADDR)

#define TIMER_CONTROL_REG \
    (*(volatile uint32_t *)TIMER_CONTROL_ADDR)

uint32_t timer_read(void)
{
    return TIMER_COUNT_REG;
}

uint32_t timer_get_compare(void)
{
    return TIMER_COMPARE_REG;
}

uint32_t timer_get_control(void)
{
    return TIMER_CONTROL_REG;
}

void timer_set_compare(uint32_t value)
{
    TIMER_COMPARE_REG = value;
}

void timer_set_control(uint32_t value)
{
    TIMER_CONTROL_REG = value;
}

void timer_enable(void)
{
    TIMER_CONTROL_REG =
        TIMER_CONTROL_REG | TIMER_ENABLE_MASK;
}

void timer_disable(void)
{
    TIMER_CONTROL_REG =
        TIMER_CONTROL_REG & ~TIMER_ENABLE_MASK;
}

void timer_enable_irq(void)
{
    TIMER_CONTROL_REG =
        TIMER_CONTROL_REG | TIMER_IRQ_EN_MASK;
}

void timer_disable_irq(void)
{
    TIMER_CONTROL_REG =
        TIMER_CONTROL_REG & ~TIMER_IRQ_EN_MASK;
}