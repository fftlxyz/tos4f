
.include "inc/pm.inc"

.set GCODE_SEL , 0x8
.set GDATA_SEL , 0x10

.globl start
start:
.code16

    cli

seta20.1:
    inb $0x64, %al
    testb $0x2, %al
    jnz seta20.1

    movb $0xd1, %al
    outb %al, $0x64

seta20.2:
    inb $0x64, %al
    testb $0x2, %al
    jnz seta20.2

    movb $0xdf, %al
    outb %al, $0x60

    movw $0, %ax
    movw %ax, %ds
    lgdt GdtPtr


    #启用分段
    movw $0x0001, %ax
    lmsw %ax

    #figure out why $, and jmp not
    ljmp $GCODE_SEL, $LABEL_GCODE
    #ljmp $0x1, $0x2

.code32
LABEL_GCODE:

    movw $GDATA_SEL, %ax
    movw %ax, %ds
    movw %ax, %fs
    movw %ax, %es
    movw %ax, %gs
    movw %ax, %ss

    mov $start, %esp

    call bootmain

    //should nerver be excuted
    jmp .


.p2align 2

LABEL_GDT:              SegDesc 0, 0, 0
LABEL_DESC_GCODE:       SegDesc 0, 0xffffffff, DA_CR | DA_32
LABEL_DESC_GDATA:       SegDesc 0, 0xffffffff, DA_32 | DA_DRW

GdtLen = . - LABEL_GDT
GdtPtr:
    .word GdtLen - 1
    .long LABEL_GDT

