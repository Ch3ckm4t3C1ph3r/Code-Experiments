; No EDD bootloader
	BITS 16
    ORG 0x7C00
start:
	jmp 0x0000:init

init:
	mov [DRIVE_ID], dl	; Saves the drive ID of the media in the DRIVE_ID variable

	cli
	xor ax,ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
	sti
	
	mov ax, 0x0003
	int 10h

    	jmp load_kernel


; -----------------------------------------------------------------------
; |				   Data					|
; -----------------------------------------------------------------------

DRIVE_ID: db 0x00

error_msg db 0x0D,0x0A,"Read Error. Error Code: ",0x00
load_msg db "Loading kernel...",0x0D,0x0A,0x00

; -----------------------------------------------------------------------
; |				Functions				|
; -----------------------------------------------------------------------

print_string:			; Routine: output string in SI to screen
	cld
	mov ah, 0x0E		; int 10h 'print char' BIOS function

.repeat:
	lodsb			; Get the character from string
	cmp al, 0x00
	je .done		; If the char obtained is the 00, end of string
	int 10h			; Otherwise, print it
	jmp .repeat

.done:
	ret


load_kernel:
	mov si, load_msg
	call print_string

	mov ax,0x0100		; Destiny address (0x0100 * 16 = 0x1000)
	mov es, ax
	mov bx, 0x0000

	mov ah, 0x02		; BIOS Function: Read sectors
	mov al, 0x05		; Number of sectors to read
	mov ch, 0x00		; Cylinder 0
	mov dh, 0x00		; Head 0
	mov cl, 0x02		; Sector 2 (sector 1 is bootloader)
	int 13h

	jc short .read_error

	mov ah, 0x86
	mov cx, 0x0000F
	mov dx, 0x4240
	int 15h

	jmp 0x0100:0x0000

.read_error:
	mov si, error_msg
	call print_string

	push ax

	mov al, ah
	shr al, 4
	call print_hexdigit

	pop ax
	mov al, ah
	and al, 0x0F
	call print_hexdigit

	cli
    	hlt

print_hexdigit:
	add al, '0'
	cmp al, '9'
	jle .is_digit

	add al, 7

.is_digit:
	mov ah, 0x0E
	int 10h
	ret

; ------------------------------------------------------------------------
; | 			     MBR Structure				 |
; ------------------------------------------------------------------------

	times 440-($-$$) db 0x00

	db 0x00,0x00,0x00,0x00
	dw 0x0000

; ------------------------------------------------------------------------
; | 			     MBR Partitions				 |
; ------------------------------------------------------------------------

	; Format: 
	; 	Off: 0x00 (1B, status; 0x80 active), 0x01 (3B, CHS first sector of partition; 1024 C, 255 H, 53 S), 0x04 (1B, partition type), 0x05 (3B, CHS final sector of partition)
	;	     0x08 (4B, Logical block address of first sector of partition), 0x0C (4B, Partition length, in sectors of 512B at least)

	; Partition 1: Active, type 0x0C ( FAT32 LBA ), starts at sector 1, max size
	db 0x80, 0x21, 0x03, 0x00, 0x0C, 0x54, 0xC8, 0xFC, 0x00, 0x08, 0x00, 0x00, 0x00, 0x80, 0xEB, 0x00
	; Partitions 2,3,4: Empty
	times 16 * 3 db 0x00

	dw 0xAA55		; The standard PC boot signature

