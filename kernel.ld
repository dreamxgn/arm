ENTRY(_start)
SECTIONS {
  . = 0x80000;
  .text : {
    *(.text)
    *(.text.*)
  }
  . = ALIGN(8);
  .data : {
    *(.data)
    *(.data.*)
  }
}
