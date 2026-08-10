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
    while (1) {
        uart_puts("A\n");

        for (volatile uint32_t i = 0; i < 50u; i++) {
        }
    }
}

static void task_b(void)
{
    while (1) {
        uart_puts("B\n");

        for (volatile uint32_t i = 0; i < 50u; i++) {
        }
    }
}

int main(void)
{
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