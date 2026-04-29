OUTPUT_FORMAT("binary")

SECTIONS
{
    . = 0x7E00;

    .entry  : { *(.entry) }

    .text   : { __text_start = .;       *(.text)    }
    .data   : { __data_start = .;       *(.data)    }
    .rodata : { __rodata_start = .;     *(.rodata)  }
    .bss    : { __bss_start = .;        *(.bss)     }

    __end = .;
}
