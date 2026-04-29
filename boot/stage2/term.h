/*
 * Isotope OS - Open Source Operating System
 * Copyright (C) 2026 Viktor Popp
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */
#pragma once
#include <stdint.h>

void term_init();
void term_enable_cursor();
void term_set_cursor(int x, int y);
uint16_t term_getchar(int x, int y);
void term_putchar(int x, int y, uint8_t color, char ch);
void term_clear_screen();

// General functions

void putc(char s);
void puts(const char *s);
int printf(const char *fmt, ...);
