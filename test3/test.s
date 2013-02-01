#include "pm.inc"

; .macro Descriptor base, limit, attr
        ; .word    \limit & 0xffff
        ; .word    \base  & 0xffff
        ; .byte    (\base >> 16) & 0xff
        ; .word    (\limit >> 8) & 0xf00 | (\attr & 0xf0ff )
        ; .byte    (\base >> 24) & 0xff
; .endm



mov %ax, %dx
