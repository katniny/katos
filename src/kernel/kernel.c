// simple kernel for now :p

// function to print a string to the screen using BIOS
void print_string(const char* str) {
    // use inline assembly to interface with BIOS (AT&T syntax)
    __asm__ __volatile__ (
        "movb $0x0E, %%ah\n" // BIOS teletype function
        "1:\n"
        "movb (%0), %%al\n" // load character
        "incw %0\n" // increment string pointer
        "testb %%al, %%al\n" // check if end of string
        "jz 2f\n" // if zero, exit
        "int $0x10\n" // call BIOS video interrupt
        "jmp 1b\n" // loop back
        "2:\n" // end label
        :
        : "r" (str)
        : "ax"
    );
}

// entry point for the C code
void kernel_main() {
    // print welcome message
    print_string("KatOS Kernel loaded successfully!\r\n");
    print_string("Starting initialization...\r\n");

    // main kernel loop
    while (1) {
        // halt the CPU until an interrupt occurs
        __asm__ __volatile__("hlt");
    }
}

// we need this to prevent the compiler from looking for a standard C entry point
void _start() {
    kernel_main();
}