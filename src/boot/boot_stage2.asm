; second stage bootloader for KatOS
BITS 16
ORG 0x7E00 ; we are loaded right after the first stage

; entry point for second stage
stage2_start:
    ; print welcome message
    mov si, stage2_msg
    call print_string

    ; check if A20 line is enabled
    call check_a20
    jnc .a20_enabled ; if carry flag is clear, A20 is already enabled
    
    ; enable A20 line
    mov si, enable_a20_msg
    call print_string
    call enable_a20
    
.a20_enabled:
    ; load the kernel from disk
    mov si, loading_kernel_msg
    call print_string
    call load_kernel

    ; check if kernel loaded correctly
    mov ax, 0x1000
    mov es, ax 
    mov eax, [es:0] ; read first dword of kernel
    cmp eax, 0 ; if its 0, kernel might not be loaded
    je .kernel_error
    
    ; if kernel seems to be present, prepare to switch to protected mode
    mov si, protected_mode_msg
    call print_string
    call switch_to_protected_mode
    
    ; we should never get here
    mov si, fail_msg
    call print_string
    jmp $ ; infinite loop
.kernel_error:
    mov si, kernel_error_msg
    call print_string 
    jmp $ ; hang

; function to print a null-terminated string
; input: SI points to string
print_string:
    push ax
    push bx
    mov ah, 0x0E ; BIOS teletype function
    mov bx, 0x0007 ; Page 0, text attribute
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

; load kernel from disk to 0x10000
load_kernel:
    ; reset disk system first
    mov ah, 0x00
    mov dl, 0x80 ; first hard drive
    int 0x13
    jc .error

    ; load the kernel
    mov ah, 0x02 ; BIOS read sector function
    mov al, 64 ; number of sectors to read (16KB should be enough for initial kernel)
    mov ch, 0 ; cylinder 0
    mov cl, 3 ; start from sector 10 (after bootloader stages)
    mov dh, 0 ; head 0
    mov dl, 0x80 ; drive number (0x80 for first hard disk)
    mov bx, 0x1000  ; set ES to 0x1000
    mov es, bx ; ES:BX = 0x1000:0x0000 = physical address 0x10000
    xor bx, bx ; set BX to 0      
    int 0x13 ; call BIOS disk interrupt
    jc .error ; if carry flag set, there was an error
    
    mov ax, 0 ; reset ES back to 0
    mov es, ax
    ret

.error:
    mov si, disk_error_msg
    call print_string
    mov ah, 0x0E
    mov al, '0'
    add al, ah ; convert error code to ASCII digit
    int 0x10
    jmp $ ; hang

; check if A20 line is enabled
; returns: Carry flag clear if A20 is enabled, set if disabled
check_a20:
    pushf
    push ds
    push es
    push di
    push si
 
    cli ; disable interrupts
 
    xor ax, ax ; set ES:DI to 0000:0500
    mov es, ax
    mov di, 0x0500
 
    mov ax, 0xFFFF ; set DS:SI to FFFF:0510
    mov ds, ax
    mov si, 0x0510
 
    mov al, byte [es:di] ; save original bytes
    push ax
    mov al, byte [ds:si]
    push ax
 
    mov byte [es:di], 0x00 ; write different values to memory
    mov byte [ds:si], 0xFF
 
    cmp byte [es:di], 0xFF ; compare values - if A20 is enabled, they should be different
 
    pop ax ; restore original values
    mov byte [ds:si], al
    pop ax
    mov byte [es:di], al
 
    mov ax, 0 ; clear AX
    je .done ; jump if equal (A20 is disabled)
    
    stc ; set carry flag if A20 is disabled
    jmp .exit
    
.done:
    clc ; clear carry flag if A20 is enabled
    
.exit:
    pop si
    pop di
    pop es
    pop ds
    popf
    ret

; enable A20 line using BIOS
enable_a20:
    mov ax, 0x2401
    int 0x15 ; call BIOS interrupt
    jc .error ; if carry flag is set, there was an error
    ret
    
.error:
    mov si, a20_error_msg
    call print_string
    jmp $ ; hang

; GDT (Global Descriptor Table)
gdt_start:
    ; null descriptor
    dq 0x0000000000000000
    
    ; code segment descriptor (64-bit)
    dw 0xFFFF ; limit (bits 0-15)
    dw 0x0000 ; base (bits 0-15)
    db 0x00 ; base (bits 16-23)
    db 10011010b ; access byte: Present, Ring 0, Code Segment, Executable, Direction 0, Readable
    db 10101111b ; flags: Granularity, 32-bit protected mode, 64-bit code segment + Limit (bits 16-19)
    db 0x00 ; base (bits 24-31)
    
    ; data segment descriptor (64-bit compatible)
    dw 0xFFFF ; limit (bits 0-15)
    dw 0x0000 ; base (bits 0-15)
    db 0x00 ; base (bits 16-23)
    db 10010010b ; access byte: Present, Ring 0, Data Segment, Direction 0, Writable
    db 10101111b ; flags: Granularity, 32-bit protected mode + Limit (bits 16-19)
    db 0x00 ; base (bits 24-31)
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1 ; size of GDT
    dd gdt_start ; address of GDT

CODE_SEG equ 0x08 ; offset in GDT for code segment (2nd entry, 8 bytes in)
DATA_SEG equ 0x10 ; offset in GDT for data segment (3rd entry, 16 bytes in)

; function to switch to protected mode
switch_to_protected_mode:
    cli ; disable interrupts
    lgdt [gdt_descriptor] ; load GDT register with our descriptor
    
    ; set PE (Protection Enable) bit in CR0
    mov eax, cr0
    or eax, 1 ; set bit 0
    mov cr0, eax
    
    ; perform far jump to 32-bit code
    jmp CODE_SEG:protected_mode_entry

; 32-bit code starts here
BITS 32
protected_mode_entry:
    ; set up segment registers for protected mode
    mov ax, DATA_SEG ; update segment registers
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; set up a new stack
    mov esp, 0x90000 ; set stack pointer
    
    ; set up page tables for long mode
    call setup_paging
    
    ; switch to long mode
    call switch_to_long_mode
    
    ; we should never get here
    hlt

; set up paging for long mode
setup_paging:
    ; clear page tables area
    mov edi, 0x9000 ; page tables will start at 0x1000
    mov cr3, edi ; set CR3 to point to PML4
    xor eax, eax
    mov ecx, 4096 ; clear 4 pages (16KB total)
    rep stosd ; repeat store doubleword
    mov edi, cr3 ; reset EDI to start of PML4
    
    ; set up page tables (identity mapping)
    ; PML4 entry (first entry points to PDPT)
    mov dword [edi], 0x9003 + 0x1000 ; Present + Write + User
    add edi, 0x1000 ; Next page (PDPT)
    
    ; PDPT entry (first entry points to PDT)
    mov dword [edi], 0x9003 + 0x2000 ; Present + Write + User
    add edi, 0x1000 ; Next page (PDT)
    
    ; PDT entry (first entry points to PT)
    mov dword [edi], 0x9003 + 0x3000 ; Present + Write + User
    add edi, 0x1000         ; Next page (PT)
    
    ; Identity map first 2MB of memory
    mov ebx, 0x00000003 ; Present + Write + User
    mov ecx, 512 ; 512 entries in PT (2MB of memory)
    
.set_entry:
    mov dword [edi], ebx ; store entry
    add ebx, 0x1000 ; next physical address (4KB)
    add edi, 8 ; next entry (8 bytes per entry)
    loop .set_entry ; repeat for all entries
    
    ret

; switch to long mode
switch_to_long_mode:
    ; enable PAE
    mov eax, cr4
    or eax, 1 << 5 ; set PAE bit
    mov cr4, eax
    
    ; enable long mode in EFER MSR
    mov ecx, 0xC0000080 ; EFER MSR
    rdmsr
    or eax, 1 << 8 ; set LME bit
    wrmsr
    
    ; enable paging (this activates long mode)
    mov eax, cr0
    or eax, 1 << 31 ; set PG bit
    mov cr0, eax
    
    ; load 64-bit GDT and jump to 64-bit code
    lgdt [gdt64_ptr]
    jmp CODE_SEG:long_mode_entry

; GDT for 64-bit mode
gdt64_start:
    ; null descriptor
    dq 0x0000000000000000
    
    ; code segment descriptor (64-bit)
    dw 0x0000 ; limit (bits 0-15) - ignored in 64-bit mode
    dw 0x0000 ; base (bits 0-15) - ignored in 64-bit mode
    db 0x00 ; base (bits 16-23) - ignored in 64-bit mode
    db 10011010b ; access byte: Present, Ring 0, Code Segment, Executable, Direction 0, Readable
    db 10101111b ; flags: Granularity, 64-bit code segment
    db 0x00 ; base (bits 24-31) - ignored in 64-bit mode
    
    ; data segment descriptor (64-bit)
    dw 0x0000 ; limit (bits 0-15) - ignored in 64-bit mode
    dw 0x0000 ; base (bits 0-15) - ignored in 64-bit mode
    db 0x00 ; base (bits 16-23) - ignored in 64-bit mode
    db 10010010b ; access byte: Present, Ring 0, Data Segment, Direction 0, Writable
    db 00000000b ; flags: All 0 for data segments in 64-bit mode
    db 0x00 ; base (bits 24-31) - ignored in 64-bit mode
gdt64_end:

gdt64_ptr:
    dw gdt64_end - gdt64_start - 1 ; size of GDT
    dq gdt64_start ; use 64-bit address (quad-word)

; 64-bit code starts here
BITS 64
long_mode_entry:
    ; update segment registers
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; IMPORTANT: debugging message to show we made it to 64-bit mode
    mov rdi, 0xB8000 ; second line in video memory
    mov rax, 0x4F4C4F474F4E4F4D ; "LONGMOD" in red
    mov [rdi], rax 
    mov rax, 0x4F454F204F454F20 ; "E E " in red 
    mov [rdi + 8], rax 

    ; give the system a moment to display
    mov rcx, 10000000
.delay_loop:
    nop 
    loop .delay_loop

    ; jump to kernel entry point
    jmp 0x10000

; data section
stage2_msg db "KatOS Bootloader Stage 2", 13, 10, 0
enable_a20_msg db "Enabling A20 line...", 13, 10, 0
loading_kernel_msg db "Loading kernel...", 13, 10, 0
protected_mode_msg db "Switching to protected mode...", 13, 10, 0
fail_msg db "Failed to execute! System halted.", 13, 10, 0
disk_error_msg db "Error loading kernel! Code: ", 0
a20_error_msg db "Error enabling A20 line!", 13, 10, 0
kernel_error_msg db "Error: Kernel not found or invalid!", 13, 10, 0