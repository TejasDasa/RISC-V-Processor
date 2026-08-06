#ifndef SOC_H
#define SOC_H

#include <stdint.h>

#define DMEM_BASE_ADDR    0x00010000u

#define UART_TX_ADDR      0x10000000u
#define UART_STATUS_ADDR  0x10000004u

#define UART_BUSY_MASK    0x00000001u

#endif