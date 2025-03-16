; first stage bootloader for KatOS (fits in 512 bytes because the compiler complains)
BITS 16
ORG 0x7C00

; main bootloader entry point
boot_start:
    ; set up the stack
    cli ; disable interrupts
    mov ax, 0x0000 ; set segments to 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00 ; set up stack pointer right below where we're loaded
    sti ; enable interrupts

    ; print welcome message
    mov si, welcome_msg
    call print_string

    ; load the second stage bootloader
    mov si, loading_msg
    call print_string
    call load_stage2
    
    ; jump to second stage
    mov si, jump_msg
    call print_string
    jmp 0:0x7E00 ; jump to second stage at 0x7E00
    
    ; We should never get here
    mov si, fail_msg
    call print_string
    jmp $ ; infinite loop

; function to print a null-terminated string
; input: SI points to string
print_string:
    push ax
    push bx
    mov ah, 0x0E ; BIOS teletype function
    mov bx, 0x0007 ; page 0, text attribute
.loop:
    lodsb ; load byte from SI into AL and increment SI
    test al, al ; check if character is null
    jz .done ; if zero, we're done
    int 0x10 ; call BIOS video interrupt
    jmp .loop ; continue with next character
.done:
    pop bx 
    pop ax 
    ret 

; load second stage bootloader from disk (sector 2)
load_stage2:
    ; reset disk system first
    mov ah, 0x00
    mov dl, 0x80 ; first hard drive
    int 0x13
    jc .error

    ; Load the second stage
    mov ah, 0x02 ; BIOS read sector function
    mov al, 8 ; number of sectors to read (4KB should be enough for stage2)
    mov ch, 0 ; cylinder 0
    mov cl, 2 ; start from sector 2 (1-based, sector 1 is the boot sector)
    mov dh, 0 ; head 0
    mov dl, 0x80 ; drive number (0x80 for first hard disk)
    mov bx, 0x7E00 ; load to address 0x7E00 (right after the boot sector)
    int 0x13 ; call BIOS disk interrupt
    jc .error ; if carry flag set, there was an error
    ret

.error:
    mov si, disk_error_msg
    call print_string
    mov ah, 0x0E
    mov al, '0'
    add al, ah ; convert error code to ASCII digit
    int 0x10
    jmp $ ; hang

; Data section
welcome_msg db "KatOS Bootloader Stage 1", 13, 10, 0
loading_msg db "Loading Stage 2...", 13, 10, 0
jump_msg db "Jumping to Stage 2...", 13, 10, 0
fail_msg db "Failed to load! System halted.", 13, 10, 0
disk_error_msg db "Disk error! Code: ", 0

; Boot signature
times 510-($-$$) db 0 ; pad the rest of the sector with zeros
dw 0xAA55 ; boot signature