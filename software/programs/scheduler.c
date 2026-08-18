#include <stdint.h>

#include "task.h"
#include "timer.h"
#include "uart.h"
#include "soc.h"

#define TICK_INTERVAL 100u

static uint32_t stack_a[128] __attribute__((aligned(16)));
static uint32_t stack_b[128] __attribute__((aligned(16)));

static void enable_interrupts(void)
{
    __asm__ volatile (
        "li t0, 0x80\n"
        "csrs mie, t0\n"

        "li t0, 0x8\n"
        "csrs mstatus, t0\n"
        :
        :
        : "t0"
    );
}

static void task_a(void)
{
    uint32_t x = 1u;
    uint32_t y = 7u;
    uint32_t iterations = 0u;

    while (1) {
        /*
         * Deterministic state update.
         */
        x += 3u;
        y ^= 0x55u;

        /*
         * Check invariants.
         *
         * x starts at 1 and only ever increases by 3.
         * y alternates between two known values.
         */
        if ((y != (7u ^ 0x55u)) &&
            (y != 7u)) {
            uart_puts("A FAIL\n");

            while (1) {
            }
        }

        iterations++;

        /*
         * Reach a milestone without division/mod.
         */
        if (iterations == 1000u) {
            uart_puts("A PASS\n");

            iterations = 0u;
            x = 1u;
            y = 7u;
        }

        /*
         * Burn some cycles so timer IRQ can preempt us
         * in different places.
         */
        for (volatile uint32_t i = 0u; i < 100u; i++) {
        }
    }
}

static void task_b(void)
{
    uint32_t x = 100u;
    uint32_t y = 0xA5u;
    uint32_t iterations = 0u;

    while (1) {
        x += 5u;
        y ^= 0x3Cu;

        if ((y != (0xA5u ^ 0x3Cu)) &&
            (y != 0xA5u)) {
            uart_puts("B FAIL\n");

            while (1) {
            }
        }

        iterations++;

        if (iterations == 1000u) {
            uart_puts("B PASS\n");

            iterations = 0u;
            x = 100u;
            y = 0xA5u;
        }

        for (volatile uint32_t i = 0u; i < 100u; i++) {
        }
    }
}

int main(void)
{
    uart_puts("SCHED TEST START\n");

    scheduler_init();

    task_create(
        0,
        task_a,
        &stack_a[128]
    );

    task_create(
        1,
        task_b,
        &stack_b[128]
    );

    timer_set_compare(
        timer_read() + TICK_INTERVAL
    );

    timer_set_control(
        TIMER_ENABLE_MASK |
        TIMER_IRQ_EN_MASK
    );

    enable_interrupts();

    scheduler_start();

    while (1) {
    }
}