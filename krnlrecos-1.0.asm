	BITS 16
    ORG 0x1000
krnl_start:
	cli
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x1000
	sti
	
	mov ax, 0x0003
	int 10h

	mov si, welcome_msg	; Put string position into SI
	call print_string	; Call string-printing routine

input_cycle:
	mov si, prompt
	call print_string
	
	; Reset the values of the registers AH, AL
	xor ax, ax		; xor ah, ah : xor al, al : mov ah, 0x00 : mov al, 0x00

	xor ah, ah		; Return: AH = BIOS scan code, AL = ASCII character
	int 16h			; BIOS Keyboard function: GET KEYSTROKE

	cmp ah, 0x1C		; Compare if the code ingresed is Enter, by the BIOS scan code
	je input_cycle

	; Display one character of input of the user
	mov ah, 0x0E
	xor bh, bh
	int 10h
	
	cmp al, "?"
	je .help

	cmp al, "q"		; Terminates the programs ('q'uits)
	je end

	mov si, unknow_msg
	call print_string

	jmp input_cycle		; Repeats the input cycle for the new input of the user

.help:
	mov si, help_msg
	call print_string

	jmp input_cycle

end:
	mov si, exit_msg
	call print_string

	mov ah, 0x86		; Indicates to the system waits a CX:DX interval of time in ms
	mov cx, 0x000F
	mov dx, 0x4240
	int 15h

	mov ax, 0x5308		; Enable/Disable Power Management
	mov bx, 0x0001		; For all devices (APM: Advanced Power Management, 0x00001 for v1.1+) 0xFFFF for APM v1.0
	mov cx, 0x0001		; Enable power management
	int 15h

	mov ax, 0x5307 		; Sets the system power state
	mov bx, 0x0001		; Selects all devices of the system to change the power state
	mov cx, 0x0003		; Power state: off (shutdown)
	int 15h

	cli
	hlt

; -----------------------------------------------------------------------
; |				   Data					|
; -----------------------------------------------------------------------

	welcome_msg db 0xC9,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xBB,0x0D,0x0A,0xBA," Welcome to RecOS ",0xBA,0x0D,0x0A,0xC8,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xCD,0xBC,0x0D,0x0A,0x00
	exit_msg db 0x0D,0x0A,"Quiting",0x0D,0x0A,0x00
	help_msg db 0x0D,0x0A,"HELP:",0x0D,0x0A,"?: Help, q: Quit",0x00
	unknow_msg db 0x0D,0x0A,"Unknow. Type ?",0x0D,0x0A,0x00
	prompt db 0x0D,0x0A,"> ",0x00

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

	times 7*512-($-$$) db 0x00
