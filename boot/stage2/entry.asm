; Isotope OS - Open Source Operating System
; Copyright (C) 2026 Viktor Popp
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program. If not, see <https://www.gnu.org/licenses/>.

bits 16         ; the assembler should emit 16-bit code

section .entry

extern __bss_start
extern __end
extern cstart

_start:
    cli
    cld

    ; setup data segments
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; setup stack
    mov ss, ax
    mov sp, 0x7C00
    mov bp, sp

    ; Enable the A20 Line
    call enable_a20
    mov si, msg_enabled_a20
    call puts

    ; Load our GDT
    call load_gdt
    mov si, msg_loaded_gdt
    call puts

    ; set the protected mode bit in CR0
    mov eax, cr0
    or eax, 0b00000001
    mov cr0, eax

    jmp dword 0x08:.pmode

.pmode:
    [bits 32]

    ; Setup segment registers
    mov ax, 0x10
    mov ds, ax
    mov ss, ax

    mov edi, __bss_start
    mov ecx, __end
    sub ecx, edi            ; ECX is the size of the bss section
    mov al, 0
    rep stosb               ; while ECX doesn't equals 0 copy AL into ES:DI, then decrement ECX

    call cstart             ; Call into C code :D

.halt:
    cli
    hlt
    jmp .halt


%define ENDL 0x0D, 0x0A

;
; print a string to the screen
; parameters:
;   - DS:SI: the string to print
;
puts:
    pusha

.loop:
    lodsb           ; load SI into AL and increment SI
    or al, al
    jz .done

    mov ah, 0x0E
    mov bh, 0       ; page zero, compatibility only
    int 0x10        ; video services, teletype output

    jmp .loop

.done:
    popa
    ret


;
; A20 Line
;

enable_a20:
    [bits 16]

    ; Enabling the A20 line to access more memory that 1 MiB is kind of weird.
    ; Because the keyboard controller was a powerful microcontroller, to reduce
    ; the costs, some general purpose I/O capabilities of the AT controller was
    ; used to control various things unrelated to the keyboard. Enabling the
    ; A20 line is one of these things.

    ; Disable the keyboard controller
    call a20_wait_input
    mov al, kbd_disable_cmd
    out kbd_cmd_port, al

    ; Request status of controller output pins
    call a20_wait_input
    mov al, kbd_read_ctrl_output_port
    out kbd_cmd_port, al

    ; Read the data and save EAX
    call a20_wait_input
    in al, kbd_data_port
    push eax

    ; Request to edit controller output pins
    call a20_wait_input
    mov al, kbd_write_ctrl_output_port
    out kbd_cmd_port, al

    ; Restore EAX, enable the A20 bit, and output to the data port
    call a20_wait_input
    pop eax
    or al, 0b00000010       ; bit 2 is the A20 bit
    out kbd_data_port, al

    ; Enable the keyboard controller
    call a20_wait_input
    mov al, kbd_enable_cmd
    out kbd_cmd_port, al

    call a20_wait_input
    ret

a20_wait_input:
    [bits 16]

    ; Wait until status bit 2 (input buffer) is 0

    in al, kbd_cmd_port
    test al, 2
    jnz a20_wait_input
    ret

kbd_data_port equ 0x60
kbd_cmd_port  equ 0x64

kbd_disable_cmd             equ 0xAD
kbd_enable_cmd              equ 0xAE
kbd_read_ctrl_output_port   equ 0xD0
kbd_write_ctrl_output_port  equ 0xD1

msg_enabled_a20: db "Enabled the A20 line", ENDL, 0


;
; Global Descriptor Table
;
load_gdt:
    [bits 16]
    lgdt [g_GDTR]
    ret

g_GDT:
    ; NULL Descriptor
    dq 0

    ; 32-bit code segment
    dw 0xFFFF               ; limit (bits 0-15)
    dw 0                    ; base (bits 0-15)
    db 0                    ; base (bits 16-23)
    db 0b10011010           ; access byte
    db 0b11001111           ; flags | limit (bits 16-19)
    db 0                    ; base (bits 24-31)

    ; 32-bit data segment
    dw 0xFFFF               ; limit (bits 0-15)
    dw 0                    ; base (bits 0-15)
    db 0                    ; base (bits 16-23)
    db 0b10010010           ; access byte
    db 0b11001111           ; flags | limit (bits 16-19)
    db 0                    ; base (bits 24-31)

    ; 16-bit code segment
    dw 0xFFFF               ; limit (bits 0-15)
    dw 0                    ; base (bits 0-15)
    db 0                    ; base (bits 16-23)
    db 0b10011010           ; access byte
    db 0b00001111           ; flags | limit (bits 16-19)
    db 0                    ; base (bits 24-31)

    ; 16-bit data segment
    dw 0xFFFF               ; limit (bits 0-15)
    dw 0                    ; base (bits 0-15)
    db 0                    ; base (bits 16-23)
    db 0b10010010           ; access byte
    db 0b00001111           ; flags | limit (bits 16-19)
    db 0                    ; base (bits 24-31)

g_GDTR:
    dw g_GDTR - g_GDT - 1   ; size of the GDT
    dd g_GDT                ; address of the GDT

msg_loaded_gdt: db "Loaded the GDT", ENDL, 0
