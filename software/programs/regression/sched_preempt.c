#include <stdint.h>

#include "task.h"
#include "timer.h"
#include "trap.h"
#include "soc.h"

/*
 * Preemptive scheduler regression.
 *
 * Two tasks are switched by the timer interrupt through
 * trap_entry -> trap_handler -> scheduler_tick. Each task keeps
 * redundant copies of its state that must always agree; any lost,
 * duplicated or corrupted instruction across a preemption breaks
 * the invariant. Task A finishes once it has observed task B make
 * progress on at least MIN_SWITCHES separate occasions.
 */

#define TICK_INTERVAL 100u
#define MIN_SWITCHES  3u

static uint32_t stack_a[128] __attribute__((aligned(16)));
static uint32_t stack_b[128] __attribute__((aligned(16)));

volatile uint32_t count_a;
volatile uint32_t count_b;
volatile uint32_t errors;

static void finish(uint32_t code)
{
    /*
     * Disable interrupts, put the result in a0 and halt on
     * "j ." (0x0000006f), which program_tb treats as the end.
     */
    __asm__ volatile (
        "csrw mstatus, zero\n"
        "mv   a0, %0\n"
        "1: j 1b\n"
        :
        : "r"(code)
    );

    while (1) {
    }
}

static void task_a(void)
{
    uint32_t x = 1u;
    uint32_t shadow = 1u;
    uint32_t last_b = count_b;
    uint32_t switches_seen = 0u;

    while (1) {
        x += 3u;
        shadow += 3u;

        if (x != shadow) {
            errors |= 1u;
        }

        count_a++;

        if (count_b != last_b) {
            last_b = count_b;
            switches_seen++;
        }

        if (switches_seen >= MIN_SWITCHES) {
            finish((errors == 0u) ? 0x600Du : (0xBAD0u | errors));
        }
    }
}

static void task_b(void)
{
    uint32_t y = 0xA5u;
    uint32_t shadow = 0xA5u;

    while (1) {
        y ^= 0x3Cu;
        shadow ^= 0x3Cu;

        if (y != shadow) {
            errors |= 2u;
        }

        count_b++;
    }
}

int main(void)
{
    scheduler_init();

    task_create(0, task_a, &stack_a[128]);
    task_create(1, task_b, &stack_b[128]);

    timer_set_compare(timer_read() + TICK_INTERVAL);
    timer_set_control(TIMER_ENABLE_MASK | TIMER_IRQ_EN_MASK);

    /*
     * Enable only mie.MTIE here. mstatus.MIE is turned on by the
     * MRET in context_start_preemptive (via MPIE), so no tick can
     * arrive while the first task's context is being restored.
     */
    __asm__ volatile (
        "li   t0, 0x80\n"
        "csrs mie, t0\n"
        :
        :
        : "t0"
    );

    scheduler_start();

    return 1;
}
