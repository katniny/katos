// KatOS 64-bit Kernel

// define some standard types for clarity
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;
typedef unsigned long long uint64_t;

// vga text mode constants
#define VGA_WIDTH 80
#define VGA_HEIGHT 25
#define VGA_MEMORY (uint8_t*)0xB8000
#define VGA_COLOR_LIGHT_GRAY 7
#define VGA_COLOR_BLACK 0

// structure to represent VGA attribute+character
struct vga_char {
    uint8_t character;
    uint8_t color;
};

// global cursor position
uint16_t cursor_x = 0;
uint16_t cursor_y = 0;

// set a specific color for the next character display
uint8_t vga_color(uint8_t fg, uint8_t bg) {
    return fg | (bg << 4);
}

// get the VGA memory index for a position
uint16_t vga_index(uint16_t x, uint16_t y) {
    return y * VGA_WIDTH + x;
}

// clear the screen
void clear_screen() {
    struct vga_char* vga = (struct vga_char*)VGA_MEMORY;
    uint8_t color = vga_color(VGA_COLOR_LIGHT_GRAY, VGA_COLOR_BLACK);

    for (uint16_t i = 0; i < VGA_WIDTH * VGA_HEIGHT; i++) {
        vga[i].character = ' ';
        vga[i].color = color;
    }
    
    cursor_x = 0;
    cursor_y = 0;
}

// print a character to the screen
void print_char(char c, uint8_t color) {
    struct vga_char* vga = (struct vga_char*)VGA_MEMORY;

    // handle special characters
    if (c == '\n') {
        cursor_x = 0;
        cursor_y++;
    } else if (c == '\r') {
        cursor_x = 0;
    } else if (c == '\t') {
        cursor_x = (cursor_x + 8) & ~(8 - 1); // align to 8 chars
    } else if (c == '\b') {
        if (cursor_x > 0) {
            cursor_x--;
            vga[vga_index(cursor_x, cursor_y)].character = ' ';
        }
    } else {
        // print regular character
        vga[vga_index(cursor_x, cursor_y)].character = c;
        vga[vga_index(cursor_x, cursor_y)].color = color;
        cursor_x++;
    }

    // handle line wrapping
    if (cursor_x >= VGA_WIDTH) {
        cursor_x = 0;
        cursor_y++;
    }

    // scroll if needed
    if (cursor_y >= VGA_HEIGHT) {
        // move all lines up
        for (uint16_t y = 1; y < VGA_HEIGHT; y++) {
            for (uint16_t x = 0; x < VGA_WIDTH; x++) {
                vga[vga_index(x, y-1)] = vga[vga_index(x, y)];
            }
        }
        
        // clear bottom line
        for (uint16_t x = 0; x < VGA_WIDTH; x++) {
            vga[vga_index(x, VGA_HEIGHT-1)].character = ' ';
            vga[vga_index(x, VGA_HEIGHT-1)].color = color;
        }
        
        cursor_y = VGA_HEIGHT - 1;
    }
}

// print a string to the screen
void print_string(const char* str, uint8_t color) {
    while (*str) {
        print_char(*str, color);
        str++;
    }
}

// print an unsigned integer in decimal format
void print_uint(uint16_t number, uint8_t color) {
    // buffer to hold the digits
    char buffer[21]; // maximum 20 digits for 64-bit integer + null terminator
    int pos = 0;

    // handle the special case of zero
    if (number == 0) {
        print_char('0', color);
        return;
    }

    // convert number to string
    while (number > 0) {
        buffer[pos++] = '0' + (number % 10);
        number /= 10;
    }

    // print in reverse order
    while (pos > 0) {
        print_char(buffer[--pos], color);
    }
}

// print an integer in hexademical format with a prefix
void print_hex(uint64_t number, uint8_t color) {
    // buffer to hold the digits
    char buffer[12]; // 16 digits for 64-bit integer + null integer
    int pos = 0;

    // handle the special case of zero
    if (number == 0) {
        print_string("0x0", color);
        return;
    }

    // convert number to hex string
    while (number > 0) {
        uint8_t digit = number % 16;
        if (digit < 10) {
            buffer[pos++] = '0' + digit;
        } else {
            buffer[pos++] = 'A' + (digit - 10);
        }
        number /= 16;
    }

    // print prefix
    print_string("0x", color);

    // print in reverse order
    while (pos > 0) {
        print_char(buffer[--pos], color);
    }
}

// simple memory copy function
void memcpy(void* dest, const void* src, uint64_t count) {
    uint8_t* d = (uint8_t*)dest;
    const uint8_t* s = (const uint8_t*)src;
    for (uint64_t i = 0; i < count; i++) {
        d[i] = s[i];
    }
}

// simple memory set function
void memset(void* dest, uint8_t val, uint64_t count) {
    uint8_t* d = (uint8_t*)dest;
    for (uint64_t i = 0; i < count; i++) {
        d[i] = val;
    }
}

// calculate the length of a string
uint64_t strlen(const char* str) {
    uint64_t len = 0;
    while (str[len]) {
        len++;
    }
    return len;
}

// entry point for the kernel
void kernel_main() {
    // set up color
    uint8_t default_color = vga_color(VGA_COLOR_LIGHT_GRAY, VGA_COLOR_BLACK);

    // clear the screen first
    clear_screen();

    // print welcome message
    print_string("KatOS 64-bit Kernel loaded successfully!\n\r", default_color);
    print_string("--------------------------------\n\r", default_color);
    print_string("Starting initialization...\n\r", default_color);

    // print some system info
    print_string("System running in 64-bit Long Mode\n\r", default_color);

    // TODO: add more kernel initialization here...

    // display a prompt
    print_string("\n\rKatOS> ", default_color);

    // main kernel loop
    while (1) {
        // halt the CPU until an interrupt occurs
        // TODO: handle input and processing here
        __asm__ volatile("hlt");
    }
}

// we need to define the entry point for the linker
// this is the function expected by the bootloader at 0x10000
void _start() {
    kernel_main();
}