OUTPUT_FORMAT("binary")

SECTIONS
{
    . = 0x7C00;

    /* Entry code that relocates to 0x500 and BPB */
    .entry : {
        *(.bpb)
        *(.entry)
        __entry_end = .;
    }

    /*
     * Place this section called .text with the VMA right after the .setup
     * The AT(...) tells us where it is in the file (the LMA)
     *
     * VMA - Where we are expected to run
     * LMA - Where we are placed in the file
     */
    .text 0x0500 + (__entry_end - 0x7C00) : AT(__entry_end) {
        *(.text)
        *(.rodata)
        *(.data)
    }

    /*
     * Place the .bss after .text in the VMA, but don't occupy any space in the LMA
     * We don't need to define symbols because in the bootsector we dont expect anything to be null terminated
     */
    .bss : {
        *(.bss)
    }

    /* Tells the BIOS that we are bootable */
    .bios_footer 0x7DFE : AT(0x7DFE) {
        SHORT(0xAA55)
    }
}
