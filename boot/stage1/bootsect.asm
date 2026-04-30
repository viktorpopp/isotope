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

bits 16


%define ENDL 0x0D, 0x0A

STAGE2_LOAD_SEGMENT equ 0x0000
STAGE2_LOAD_OFFSET  equ 0x7C00


section .bpb

SECTOR_SIZE         equ 512
SECTORS_PER_CLUSTER equ 1
RESERVED_SECTORS    equ 1
FAT_COUNT           equ 2
ROOT_ENTRIES        equ 0xE0
SECTORS_PER_FAT     equ 9
SECTORS_PER_TRACK   equ 18
HEAD_COUNT          equ 2

FAT_REGION_SIZE     equ FAT_COUNT * SECTORS_PER_FAT
ROOT_DIR_LBA        equ FAT_REGION_SIZE + RESERVED_SECTORS
ROOT_DIR_SIZE       equ (ROOT_ENTRIES * 32) / SECTOR_SIZE                                   ; in sectors
DATA_REGION_LBA     equ RESERVED_SECTORS + (FAT_COUNT * SECTORS_PER_FAT) + ROOT_DIR_SIZE

jmp short _start
nop

bpb:
.oem_id:                db "ISOTOPE "               ; 8 bytes        
.sector_size:           dw SECTOR_SIZE
.sectors_per_cluster:   db SECTORS_PER_CLUSTER
.reserved_sectors:      dw RESERVED_SECTORS
.fat_count:             db FAT_COUNT
.root_entries:          dw ROOT_ENTRIES
.sector_count:          dw 2880                     ; 2880 * 512 = 1.44 MB
.media_type:            db 0xF0                     ; 0xF0 = 3.5" floppy disk
.sectors_per_fat:       dw SECTORS_PER_FAT
.sectors_per_track:     dw SECTORS_PER_TRACK
.head_count:            dw HEAD_COUNT
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

    ; read the root directory
    mov cl, ROOT_DIR_SIZE           ; sectors to read
    mov ax, ROOT_DIR_LBA            ; LBA of root directory
    mov dl, [ebr.drive_number]
    mov bx, buffer
    call floppy_read

    xor bx, bx                  ; current directory entry index
    mov di, buffer              ; root directory

.search_stage2:
    mov si, stage2_pathname
    mov cx, 11              ; which is 11 characters
    push di                 ; (modified by cmpsb)
    repe cmpsb              ; compare DS:SI with ES:DI CX times
    pop di
    je .found_stage2

    add di, 32              ; next entry adress
    inc bx                  ; next entry index
    cmp bx, ROOT_ENTRIES
    jl .search_stage2

    jmp stage2_not_found_error

.found_stage2:
    ; DI now has the entry address
    mov ax, [di + 26]           ; first cluster field, offset 26
    mov [stage2_cluster], ax

    ; read the FAT into memory
    mov ax, RESERVED_SECTORS        ; it is placed right after the reserved sectors
    mov bx, buffer
    mov cl, [bpb.sectors_per_fat]
    mov dl, [ebr.drive_number]
    call floppy_read

    mov bx, STAGE2_LOAD_SEGMENT
    mov es, bx
    mov bx, STAGE2_LOAD_OFFSET

.load_stage2_loop:
    mov ax, [stage2_cluster]

    ; right now we onlt have the cluster within the data region itself
    ;
    ; we now convert it to the correct LBA

    sub ax, 2                       ; the first 2 clusters are reserved
    mov cx, SECTORS_PER_CLUSTER
    mul cx                          ; AX *= sectors per cluster
    add ax, DATA_REGION_LBA         ; start LBA (sector) of the data region

    mov cl, 1
    mov dl, [ebr.drive_number]
    call floppy_read

    add bx, [bpb.sector_size]       ; move the stage 2 load offset

    ; find the next cluster number
    mov ax, [stage2_cluster]
    mov cx, 3
    mul cx
    mov cx, 2
    div cx

    ; AX is now AX * 3 / 2
    ; if the cluster is odd we use the high 12 bits of the word
    ; if the cluster is even we use the lower 12 bits of the word

    mov si, buffer
    add si, ax
    mov ax, [ds:si]     ; read the cluster numbar from the FAT

    or dx, dx
    jz .even

.odd:   
    shr ax, 4
    jmp .next_cluster

.even:
    and ax, 0x0FFF

.next_cluster:
    cmp ax, 0x0FF8
    jae .read_finish

    mov [stage2_cluster], ax
    jmp .load_stage2_loop

.read_finish:
    mov dl, [ebr.drive_number]

    mov ax, STAGE2_LOAD_SEGMENT
    mov ds, ax
    mov es, ax

    jmp STAGE2_LOAD_SEGMENT:STAGE2_LOAD_OFFSET

    jmp wait_key_and_reboot

halt:
    cli
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


;
; convert LBA to CHS address
; parameters:
;   - AX: logical block address
; returns:
;   - CX [bits 0-5]: sector number
;   - CX [bits 6-15]: cylinder
;   - DH: head
;
lba_to_chs:
    push ax
    push dx

    xor dx, dx

    div word [bpb.sectors_per_track]    ; AX = LBA / sectors per track
                                        ; DX = LBA % sectors per track

    inc dx                              ; DX = DX + 1 which is the sector
    mov cx, dx                          ; now CX has the sector

    xor dx, dx

    div word [bpb.head_count]           ; AX = AX / head count which is cylinder
                                        ; DX = AX % head count which is head

    ; AX = cylinder
    ; DX = head
    ; CX = sector

    mov dh, dl

    ; CX =       ---CH--- ---CL---
    ; cylinder : 76543210 98
    ; sector   :            543210

    mov ch, al

    ; now set the weird 2 bits
    ; AH before (from AX) : 0 0 0 0 0 0 9 8 <- the 9 and 8 are bits, not numbers
    ; AH after            : 9 8 0 0 0 0 0 0
    shl ah, 6

    or cl, ah       ; now OR it with cl which already contains the sector number (from cx)

    pop ax
    mov dl, al      ; restore DL, and not DH (the head)
    pop ax
    ret


;
; read sectors from a floppy
; parameters:
;   - AX: logical block address
;   - CL: sector count
;   - DL: drive number
;   - ES:BX: memory buffer
;
floppy_read:
    pusha

    push cx
    call lba_to_chs
    pop ax

    ; AL now has the sector count and CX has sector number and cylinder

    mov ah, 0x2         ; read sectors
    mov di, 3           ; retry count

.retry:
    pusha
    stc

    int 0x13            ; disk services
    jnc .done

    ; read failed
    popa
    call floppy_reset

    dec di
    test di, di
    jnz .retry

.fail:
    jmp floppy_error

.done:
    popa

    popa
    ret


;
; reset the floppy disk controller
; parameters:
;   - DL: drive number
;
floppy_reset:
    pusha

    mov ah, 0
    stc
    int 0x13
    jc floppy_error

    popa
    ret


stage2_not_found_error:
    mov si, msg_stage2_not_found
    call puts
    jmp wait_key_and_reboot

floppy_error:   
    mov si, msg_floppy_error
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0       ; read keypress
    int 0x16        ; keyboard services
    jmp 0xFFFF:0    ; jump to the beginning of BIOS code


section .rodata

msg_loading: db "Loading...", ENDL, 0
msg_floppy_error: db "Floppy error!", 0
msg_stage2_not_found: db "Couldn't find STAGE2.BIN", 0
stage2_pathname: db 'STAGE2  BIN'

section .bss
buffer: resb ROOT_ENTRIES * 32          ; root directory buffer (7 KiB)
                                        ; the FAT is also only 4.5 KiB
stage2_cluster: resw 1
