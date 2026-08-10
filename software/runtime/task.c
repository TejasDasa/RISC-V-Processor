#include "task.h"

static task_t tasks[MAX_TASKS];

static int current_task = 0;
static int task_count = 0;

extern void context_switch(
    uint32_t **old_sp,
    uint32_t *new_sp
);

extern void context_start_preemptive(
    uint32_t *new_sp
);

void scheduler_init(void)
{
    current_task = 0;
    task_count = 0;

    for (int i = 0; i < MAX_TASKS; i++) {
        tasks[i].sp = 0;
    }
}

void task_yield(void)
{
    if (task_count < 2) {
        return;
    }

    int old = current_task;
    int next = current_task + 1;

    if (next >= task_count) {
        next = 0;
    }

    current_task = next;

    context_switch(
        &tasks[old].sp,
        tasks[next].sp
    );
}

void task_create(
    int id,
    void (*entry)(void),
    uint32_t *stack_top
)
{
    if (id < 0 || id >= MAX_TASKS) {
        return;
    }

    uint32_t *sp = stack_top;

    sp -= 32;

    // create 32 words of space and 0 it out

    for (int i = 0; i < 32; i++) {
        sp[i] = 0;
    }

    // mepc is the 30th entry

    sp[30] = (uint32_t)entry;

    tasks[id].sp = sp;

    task_count++;
}

void scheduler_start(void)
{
    if (task_count == 0) {
        return;
    }

    current_task = 0;

    context_start_preemptive(tasks[0].sp);

    while (1) {
    }
}

uint32_t *scheduler_tick(
    uint32_t *current_sp
)
{
    if (task_count < 2) {
        return current_sp;
    }

    tasks[current_task].sp = current_sp;

    int next = current_task + 1;

    if (next >= task_count) {
        next = 0;
    }

    current_task = next;

    /*
     * trap_entry.S will load this value into sp,
     * restore registers from it, restore mepc,
     * then execute mret.
     */
    return tasks[current_task].sp;
}