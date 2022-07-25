#ifndef _DEV__PS2_H
#define _DEV__PS2_H

#include <stdint.h>

uint8_t ps2_read(void);
void ps2_write(uint16_t port, uint8_t value);
uint8_t ps2_read_config(void);
void ps2_write_config(uint8_t value);
void ps2_init(void);

#endif