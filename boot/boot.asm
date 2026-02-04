section .text
bits 16
org         0x7C00
global _start
_start:
	jmp    0x0000:real_start  ; ensure CS = 0x0000
real_start:
	cli

	; setup segments
	xor     ax, ax
	mov     ds, ax
	mov     ss, ax

	mov     sp, 0x2000

	sti

	push    dx          ; save drive reference

	mov     si, LOADING_STR
	call    message

	; load 64K from the disk into 0x10000
	mov     ah, 0x42
	pop     dx          ; restore drive reference */
	mov     si, DAP
	int     0x13        ; extended read from disk */
	jnc     disk_read_success
	mov     si, DISK_ERR_STR
	call    message
.hang:
	jmp     .hang
disk_read_success:

	; change video mode
	mov     ah, 0x00
	mov     al, 0x13
	int     0x10

	; enable protected (32 bit) mode
	cli

	in      al, 0x92 ; enable A20 line
	or      al, 2
	out     0x92, al

	lgdt    [GDTD]      ; load global descriptor table
	mov     eax, cr0
	or      eax, 1
	mov     cr0, eax
	jmp     0x08:clear_pipe ; clear instruction pipeline
bits 32
clear_pipe:
	mov     ax, 0x10      ; 2nd GDT entry for data segment
	mov     ds, ax
	mov     ss, ax
	mov     esp, 0x00070000 ; almost top of 480K memory space
	jmp     0x00010000
bits 16
;
; message: write the string pointed to by %si
; WARNING: trashes %si, %ax, and %bx
;
message_loop:
	mov     bx, 0x0001
	mov     ah, 0xe
	int     0x10   ; display a byte
message:
	lodsb
	cmp     al, 0
	jne     message_loop    ; if not end of string, jmp to display
	ret

LOADING_STR:
	db      `Loading os...\r\n`,0

DISK_ERR_STR:
	db      `ERROR: Unable to read disk.\r\n`,0

; Disk Address Packet
DAP:
	db      0x10	; size of DAP
	db      0x00    ; unused (0)
	dw      32	; read 128 sectors, 64 KB
	dw      0x0000	; offset of destination memory buffer
	dw      0x1000	; segment of destination memory buffer
	dq      1	; first LBA

; GDT
	align   16
GDTD:
	dw      GDT_END - GDT - 1
	dd      GDT

	align   16
GDT:
GDT_NULL:
	dq      0
GDT_CODE:
	dw      0xFFFF		; limit 0:15
	dw      0x0000		; base 0:15
	db      0x00		; base 16:23
	db      0b10011010	; type and attributes
	db      0b11001111	; limit 16:19 (0xF) and attributes
	db      0x00		; base 24:31
GDT_DATA_SEGMENT:
	dw      0xFFFF		; limit 0:15
	dw      0x0000		; base 0:15
	db      0x00		; base 16:23
	db      0b10010010	; type and attributes
	db      0b11001111	; limit 16:19 (0xF) and attributes
	db      0x00		; base 24:31
GDT_END:

; Pad boot code up to 440 bytes (0x1B8)
    times   440 - ($ - $$) db 0

; Disk ID - 4 bytes (you can set to zero or preserve original)
disk_id:
    db 0, 0, 0, 0

    dw  0x0000 ; not copy protected

; Partition table - 64 bytes
partition_table:
    times   64 db 0

; Boot signature
    dw      0xAA55
