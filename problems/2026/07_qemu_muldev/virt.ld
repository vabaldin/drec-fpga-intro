ENTRY(_start)
SECTIONS
{
    .text 0x40010000 : { start.o(.text) *(.text .text.*) }
    .rodata : { *(.rodata .rodata.*) }
    .ARM.exidx : { *(.ARM.exidx*) }
    .data : { *(.data .data.*) }
    .bss : { *(.bss .bss.* COMMON) }
    stack_top = ALIGN(8) + 0x1000;
}
