ENTRY(_start)

MEMORY
{
    IMEM (rx)  : ORIGIN = 0x00000000, LENGTH = 64K
    DMEM (rw)  : ORIGIN = 0x00010000, LENGTH = 8K
}

SECTIONS
{
    .text : ALIGN(4)
    {
        KEEP(*(.text.init))
        *(.text*)
    } > IMEM

    .rodata : ALIGN(4)
    {
        *(.rodata*)
        *(.srodata*)
    } > DMEM

    .data : ALIGN(4)
    {
        __data_start = .;

        *(.data*)
        *(.sdata*)

        . = ALIGN(4);
        __data_end = .;
    } > DMEM

    .bss (NOLOAD) : ALIGN(4)
    {
        __bss_start = .;

        *(.bss*)
        *(.sbss*)
        *(COMMON)

        . = ALIGN(4);
        __bss_end = .;
    } > DMEM

    __stack_top = ORIGIN(DMEM) + LENGTH(DMEM);
}