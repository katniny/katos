OUTPUT_FORMAT(pe-x86-64)
ENTRY(_start)

SECTIONS {
    /* the kernel will be loaded at 0x10000 physical address */
    . = 0x10000;

    .text : {
        *(.text)
    }

    .rodata : {
        *(.rodata)
    }

    .data : {
        *(.data)
    }

    .bss : {
        *(COMMON)
        *(.bss)
    }
}