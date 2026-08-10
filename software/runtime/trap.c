#include <stdint.h>

#include "trap.h"
#include "timer.h"
#include "task.h"

#define TIMER_TICK_INTERVAL 1000u

volatile uint32_t system_ticks = 0;

static inline uint32_t read_mcause(void)
{
    uint32_t value;

    __asm__ volatile (
        "csrr %0, mcause"
        : "=r"(value)
    );

    return value;
}

static void timer_interrupt_handler(void)
{
    system_ticks++;

    timer_set_compare(
        timer_get_compare() + TIMER_TICK_INTERVAL
    );
}

uint32_t *trap_handler(
    uint32_t *current_sp
)
{
    uint32_t cause = read_mcause();

    if (cause == MCAUSE_MACHINE_TIMER) {
        system_ticks++;

        timer_set_compare(
            timer_get_compare() + TIMER_TICK_INTERVAL
        );

        return scheduler_tick(current_sp);
    }

    return current_sp;
}