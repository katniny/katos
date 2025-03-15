BITS 16
ORG 0x8000

; kernel entry point
kernel_start:
    ; set up data segments
    mov ax, 0
    mov ds, ax
    mov es, ax 

    ; print message
    mov si, kernel_msg
    call print_string 

    ; hang
    jmp $

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

; data
kernel_msg db "KatOS Kernel loaded successfully!", 13, 10, "Running in 16-bit mode.", 13, 10, 0