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
#include "term.h"
#include "io.h"
#include <stdarg.h>
#include <stdint.h>

#define SCREEN_WIDTH  80
#define SCREEN_HEIGHT 25

#define VGA_MISC_WRITE_REG 0x3C2
#define VGA_MISC_READ_REG  0x3CC
#define VGA_CTRL_INDEX_REG 0x3D4
#define VGA_CTRL_DATA_REG  0x3D5

#define VGA_CTRL_CURSOR_START 0x0A
#define VGA_CTRL_CURSOR_END   0x0B
#define VGA_CTRL_CURSOR_HIGH  0x0E
#define VGA_CTRL_CURSOR_LOW   0x0F

uint16_t *screen_buffer = (uint16_t *)0xB8000;
int screen_x;
int screen_y;

void _scrollback();

void term_init()
{
    uint8_t misc_reg = inb(VGA_MISC_READ_REG);

    // Set the first bit. This tells the video card that we use regular VGA.
    misc_reg |= 0b00000001;

    outb(VGA_MISC_WRITE_REG, misc_reg);

    term_set_cursor(0, 0);
}

// Enable a full block cursor
void term_enable_cursor()
{
    // Set the start to the first scanline
    outb(VGA_CTRL_INDEX_REG, VGA_CTRL_CURSOR_START);
    outb(VGA_CTRL_DATA_REG, (inb(VGA_CTRL_DATA_REG) & 0xC0) | 0);

    // Set the end to the last scanline
    outb(VGA_CTRL_INDEX_REG, VGA_CTRL_CURSOR_END);
    outb(VGA_CTRL_DATA_REG, (inb(VGA_CTRL_DATA_REG) & 0xE0) | 15);
}

void term_set_cursor(int x, int y)
{
    screen_x = x;
    screen_y = y;

    uint16_t pos = y * SCREEN_WIDTH + x;

    outb(VGA_CTRL_INDEX_REG, VGA_CTRL_CURSOR_LOW);
    outb(VGA_CTRL_DATA_REG, pos & 0xFF);
    outb(VGA_CTRL_INDEX_REG, VGA_CTRL_CURSOR_HIGH);
    outb(VGA_CTRL_DATA_REG, (pos >> 8) & 0xFF);
}

void term_putchar(int x, int y, uint8_t color, char ch)
{
    screen_buffer[y * 80 + x] = ch | (color << 8);
}

uint16_t term_getchar(int x, int y)
{
    return screen_buffer[y * 80 + x];
}

void putc(char c)
{
    switch (c)
    {
    case '\n':
        screen_x = 0;
        screen_y++;
        break;
    default:
        term_putchar(screen_x, screen_y, 0b00000111, c); // color = white
        screen_x++;
        break;
    }

    if (screen_x >= SCREEN_WIDTH)
    {
        screen_y++;
        screen_x = 0;
    }

    if (screen_y >= SCREEN_HEIGHT)
    {
        _scrollback();
    }

    term_set_cursor(screen_x, screen_y);
}

void puts(const char *s)
{
    while (*s)
    {
        putc(*s);
        s++;
    }
}

void term_clear_screen()
{
    for (int y = 0; y < SCREEN_HEIGHT; y++)
    {
        for (int x = 0; x < SCREEN_WIDTH; x++)
        {
            term_putchar(x, y, 0b00000111, '\0');
        }
    }
}

#define NANOPRINTF_USE_FIELD_WIDTH_FORMAT_SPECIFIERS     1
#define NANOPRINTF_USE_PRECISION_FORMAT_SPECIFIERS       1
#define NANOPRINTF_USE_FLOAT_FORMAT_SPECIFIERS           0
#define NANOPRINTF_USE_SMALL_FORMAT_SPECIFIERS           1
#define NANOPRINTF_USE_LARGE_FORMAT_SPECIFIERS           1
#define NANOPRINTF_USE_BINARY_FORMAT_SPECIFIERS          1
#define NANOPRINTF_USE_WRITEBACK_FORMAT_SPECIFIERS       0
#define NANOPRINTF_SNPRINTF_SAFE_TRIM_STRING_ON_OVERFLOW 1

#define NANOPRINTF_IMPLEMENTATION
#include "nanoprintf.h"

int printf(const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);

    char buf[1024];
    int len = npf_vsnprintf(buf, sizeof(buf), fmt, args);

    if (len < 0 || len >= (int)sizeof(buf))
    {
        return -1;
    }

    puts(buf);

    va_end(args);
    return len;
}

void _scrollback()
{
    for (int y = 1; y < SCREEN_HEIGHT; y++)
    {
        for (int x = 0; x < SCREEN_WIDTH; x++)
        {
            uint16_t c = term_getchar(x, y);
            term_putchar(x, y - 1, (uint8_t)(c >> 8), (char)(c & 0xFF));
        }
    }

    for (int x = 0; x < SCREEN_WIDTH; x++)
    {
        term_putchar(x, SCREEN_HEIGHT - 1, 0b00000111, '\0');
    }

    screen_y--;
}
