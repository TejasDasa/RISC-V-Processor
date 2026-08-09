#include <stdint.h>

#include "timer.h"
#include "trap.h"
#include "soc.h"

#define TEST_TICK_INTERVAL 50u
#define TARGET_TICKS       5u

int main(void)
{
    /*
     * Enable machine timer interrupts.
     *
     * mie.MTIE    = bit 7
     * mstatus.MIE = bit 3
     */
    __asm__ volatile (
        "li t0, 0x80\n"
        "csrs mie, t0\n"

        "li t0, 0x8\n"
        "csrs mstatus, t0\n"
        :
        :
        : "t0"
    );

    /*
     * Start the periodic timer.
     */
    timer_set_compare(
        timer_read() + TEST_TICK_INTERVAL
    );

    timer_set_control(
        TIMER_ENABLE_MASK |
        TIMER_IRQ_EN_MASK
    );

    /*
     * Normal foreground work.
     *
     * system_ticks is updated asynchronously
     * by the timer interrupt handler.
     */
    volatile uint32_t work = 0;

    while (system_ticks < TARGET_TICKS) {
        work++;
    }

    /*
     * Stop the timer so we don't keep receiving interrupts
     * after the test finishes.
     */
    timer_disable();

    /*
     * Return number of interrupts received.
     */
    return (int)system_ticks;
}