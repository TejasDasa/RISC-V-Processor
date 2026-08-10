#ifndef TASK_H
#define TASK_H

#include <stdint.h>

#define MAX_TASKS 2

typedef struct {
    uint32_t *sp;
} task_t;

void scheduler_init(void);

void task_create(
    int id,
    void (*entry)(void),
    uint32_t *stack_top
);

void scheduler_start(void);

uint32_t *scheduler_tick(
    uint32_t *current_sp
);

#endif