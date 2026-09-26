#include <stdint.h>

#include "task.h"
#include "timer.h"
#include "soc.h"

/*
 * Waveform demo 07: preemptive two-task context switch.
 *
 * Task A writes 0xA to GPIO in a loop, task B writes 0xB. The timer
 * interrupt preempts A, the runtime trap path
 *
 *     trap_entry (save 29 regs + mepc on A's stack)
 *       -> trap_handler -> scheduler_tick (pick B, return B's sp)
 *       -> restore B's registers + mepc from B's stack -> mret
 *
 * resumes B, and gpio_out flips from 0xA to 0xB. The next tick
 * switches back to A, which sees that B made progress and halts.
 *
 * In the waveform: gpio_out = which task runs, x2_sp jumps between
 * the two stacks, bus_write_en / bus_read_en show the context save
 * and restore bursts, and ex_take_mret / mepc show the resume.
 *
 * The dump starts at the first MRET (-GDUMP_START_ON_MRET=1 in
 * 07_sched_preempt.flags). Key cycles (from the PIPE log):
 *
 *   1396  MRET (context_start_preemptive) -> task_a, MIE <- MPIE
 *   1408  gpio_out = 0xA, sp = 0x10170 (A's stack)
 *   1480  timer IRQ: trap_enter, A's loop instruction killed,
 *         PC -> trap_entry; store burst saves A's context
 *   1697  MRET -> mepc = task_b (0x94); load burst restored B
 *   1750  gpio_out = 0xB, sp = 0x102f0 (B's stack)
 *   1864  timer IRQ: B preempted, B's context saved
 *   2080  MRET -> mepc = 0x78, the exact instruction A was
 *         preempted on; sp back to A's stack
 *   2091  gpio_out = 0xA; A sees count_b != 0 and halts
 */

#define FIRST_TICK 150u
#define DEMO_TICK  150u

#define GPIO_OUT (*(volatile uint32_t *)GPIO_OUT_ADDR)

/*
 * Stacks live in .data (preloaded from the DMEM image) rather than
 * .bss, so crt0 does not spend ~1300 cycles zeroing them.
 */
static uint32_t stack_a[96]
    __attribute__((aligned(16), section(".data")));
static uint32_t stack_b[96]
    __attribute__((aligned(16), section(".data")));

volatile uint32_t count_a;
volatile uint32_t count_b;

static void task_a(void)
{
    while (1) {
        GPIO_OUT = 0xAu;
        count_a++;

        if (count_b != 0u) {
            /* Back on A after B ran: disable interrupts and halt. */
            __asm__ volatile (
                "csrw mstatus, zero\n"
                "mv   a0, %0\n"
                "1: j 1b\n"
                :
                : "r"(0x600Du)
            );
        }
    }
}

static void task_b(void)
{
    /*
     * The runtime handler re-arms the timer 1000 cycles out. Pull
     * the next tick in so the switch back to A comes quickly.
     */
    timer_set_compare(timer_read() + DEMO_TICK);

    while (1) {
        GPIO_OUT = 0xBu;
        count_b++;
    }
}

int main(void)
{
    scheduler_init();

    task_create(0, task_a, &stack_a[96]);
    task_create(1, task_b, &stack_b[96]);

    timer_set_compare(timer_read() + FIRST_TICK);
    timer_set_control(TIMER_ENABLE_MASK | TIMER_IRQ_EN_MASK);

    /* MTIE only; MIE comes from MPIE on the first task's MRET. */
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
