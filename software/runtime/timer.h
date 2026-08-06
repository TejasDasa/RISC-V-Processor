#ifndef TIMER_H
#define TIMER_H

#include <stdint.h>

uint32_t timer_read(void);
uint32_t timer_get_compare(void);
uint32_t timer_get_control(void);

void timer_set_compare(uint32_t value);
void timer_set_control(uint32_t value);

void timer_enable(void);
void timer_disable(void);

void timer_enable_irq(void);
void timer_disable_irq(void);

#endif