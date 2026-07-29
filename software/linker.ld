ENTRY(_start)

SECTIONS
{
    . = 0x00000000;

    .text : {
        *(.text.init)
        *(.text*)
    }

    .rodata : {
        *(.rodata*)
    }

    .data : {
        *(.data*)
    }

    .bss : {
        . = ALIGN(4);
        __bss_start = .;

        *(.bss*)
        *(COMMON)

        . = ALIGN(4);
        __bss_end = .;
    }
}