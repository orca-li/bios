OUTPUT_FORMAT("elf32-i386")
OUTPUT_ARCH(i386)
ENTRY(_start)

SECTIONS
{
    .text 0x0000:
    {
        *(.text)
    } = 0x00

    .rodata ALIGN(4):
    {
        *(.rodata)
    } = 0x00

    .data ALIGN(4):
    {
        *(.data)
    } = 0x00

    .bss ALIGN(4):
    {
        *(.bss)
    } = 0x00
}