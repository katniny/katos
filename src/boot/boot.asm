BITS 16
ORG 0x7C00

; main bootloader entry point
boot_start:
    ; set up the stack
    cli ; disable interruptions
    mov ax, 0x0000 ; set segments to 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00 ; set up stack pointer right below where we're loaded
    sti ; enable interrupts

    ; print welcome message
    mov si, welcome_msg
    call print_string

    ; load the second stage (C)
    mov si, loading_msg
    call print_string
    call load_kernel
    
    ; jump to our loaded code
    mov si, jump_msg
    call print_string
    jmp 0:0x8000

    ; if we get here, something went wrong
    mov si, fail_msg
    call print_string
    jmp $ ; infinite loop

; function to print a null-terminated string
; input: SI points to string
print_string:
    push ax
    push bx
    mov ah, 0x0E
    mov bx, 0x0007
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop 
.done:
    pop bx 
    pop ax 
    ret 

; load kernel from disk
load_kernel:
    ; reset disk system first
    mov ah, 0x00
    mov dl, 0x80
    int 0x13
    jc .error

    ; load the kernel
    mov ah, 0x02 ; BIOS read sector function
    mov al, 4 ; number of sectors to read
    mov ch, 0 ; cylinder 0
    mov cl, 2 ; start from sector 2 (1-based, sector 1 is the boot sector)
    mov dh, 0 ; head 0
    mov dl, 0x80 ; drive number (0x80 for first hard disk)
    mov bx, 0x8000 ; load to ES:BX = 0:8000
    int 0x13 ; call BIOS disk interrupt
    jc .error ; if carry flag set, there was an error
    ret

.error:
    mov si, disk_error_msg
    call print_string
    ; display error code
    mov ah, 0x0E
    mov al, '0'
    add al, ah ; Convert error code to ASCII digit
    int 0x10
    jmp $ ; hang

; data section
welcome_msg db "Welcome to KatOS Bootloader!", 13, 10, 0
loading_msg db "Loading kernel...", 13, 10, 0
jump_msg db "Jumping to kernel...", 13, 10, 0
fail_msg db "Failed to execute kernel!", 13, 10, 0
disk_error_msg db "Error loading kernel! Code: ", 0

; boot signature
times 510-($-$$) db 0 ; pad the rest of the sector with zeros
dw 0xAA55