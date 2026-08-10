#ifndef TRAP_H
#define TRAP_H

#include <stdint.h>

#define MCAUSE_MACHINE_TIMER  0x80000007u
#define MCAUSE_ILLEGAL_INSTR  0x00000002u
#define MCAUSE_ECALL          0x0000000Bu
#define TIMER_TICK_INTERVAL 1000u

extern volatile uint32_t system_ticks;

uint32_t *trap_handler(uint32_t *current_sp);

#endif