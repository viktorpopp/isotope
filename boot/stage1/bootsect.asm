; Isotope OS - Open Source Operating System
; Copyright (C) 2026-present Viktor Popp
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

bits 16


%define ENDL 0x0D, 0x0A


section .bpb

jmp short _start
nop

bpb:
.oem_id:                db "ISOTOPE "               ; 8 bytes        
.sector_size:           dw 512
.sectors_per_cluster:   db 1
.reserved_sectors:      dw 1
.fat_count:             db 2
.root_entries:          dw 0xE0
.sector_count:          dw 2880                     ; 2880 * 512 = 1.44 MB
.media_type:            db 0xF0                     ; 0xF0 = 3.5" floppy disk
.sectors_per_fat:       dw 9
.sectors_per_track:     dw 18
.head_count:            dw 2
.hidden_sector_count:   dd 0
.large_sector_count:    dd 0
ebr:
.drive_number:          db 0                        ; 0x00 = first floppy disk, this is temporary and machine-specific
                        db 0                        ; reserved
.signature:             db 0x29
.volume_id:             db 0x12, 0x34, 0x56, 0x78   ; serial number
.volume_label:          db "ISOTOPE    "            ; 11 bytes
.filesystem_id:         db "FAT12   "               ; 8 bytes


section .entry

_start:
    cli         ; make sure we don't get spurious interrupts
    cld         ; process things from start to end

    ; zero our data segments to the offset is the literal address
    xor ax, ax
    mov ds, ax
    mov es, ax

    mov ss, ax
    mov sp, 0x7C00      ; place the stack right below where we load stage 2

    mov si, sp          ; SP is already 0x7C00, so we save a byte
    mov di, 0x500
    mov cx, 256         ; we want to move 256 words (the boot sector)
    repnz movsw         ; repnz - while CX != 0, run MOVSW and decrement CX
                        ; movsw - move [SI] to [DI]

    jmp 0x0000:_continue


section .text

_continue:
    mov [ebr.drive_number], dl      ; save our drive number so we don't overwrite it

    mov si, msg_loading
    call puts

halt:
    hlt
    jmp halt


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


section .rodata

msg_loading: db "Hello from Isotope OS", ENDL, 0
