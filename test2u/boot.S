.include "pm.inc"

.set GCODE_SEL , 0x8
.set GDATA_SEL , 0x10
.set SCRN_SEL , 0x18
.set LDT_SEL , 0x20

.set LCODE_SEL, 0x8 | SA_TIL
.set LDATA_SEL, 0x10 | SA_TIL

.globl start

start:
.code16

    mov $msgr, %ax
    mov %ax, %bp
    movw (msgrlen), %cx
    movw $0x1301, %ax # Ah = 13h, AL = 10H
    movw $0x000c, %bx # BH=0页号 BL=颜色
    movb $20, %dh    # DH = row 
    movb $0, %dl    # DL = column
    int $0x10

#   jmp .

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

    # setup gdt
    mov $LABEL_DESC_LDT, %edi
    movw $LABEL_LDT, 2(%edi)

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

    movw $SCRN_SEL, %ax
    movw %ax, %es
    movw $(21 * 160), %di

    movw $GDATA_SEL, %ax
    movw %ax, %ds
    movw $msgg, %si

    movw msgglen, %cx
1:
    cmpw $0x0, %cx
    dec %cx
    jz  1f
    movb (%si), %al
    movb %al, %es:(%di)
    inc %di
    movb $0xc, %es:(%di)
    inc %di
    inc %si
    jmp 1b
1:
    movw $LDT_SEL, %ax
    lldt %ax

    ljmp $LCODE_SEL, $LABEL_LCODE


LABEL_LCODE:

    movw $LDATA_SEL, %ax
    movw %ax, %ds

    movw $SCRN_SEL, %ax
    movw %ax, %es
    movw $(22 * 160), %di

    movw $GDATA_SEL, %ax
    movw %ax, %ds
    movw $msgl, %si

    movw msgllen, %cx
1:
    cmpw $0x0, %cx
    dec %cx
    jz  1f
    movb (%si), %al
    movb %al, %es:(%di)
    inc %di
    movb $0xc, %es:(%di)
    inc %di
    inc %si
    jmp 1b
1:
    jmp .


.p2align 2

LABEL_GDT:              SegDesc 0, 0, 0
LABEL_DESC_GCODE:       SegDesc 0, 0xffffffff, DA_CR | DA_32
LABEL_DESC_GDATA:       SegDesc 0, 0xffffffff, DA_32 | DA_DRW
LABEL_DESC_SCRN:        SegDesc 0xb8000, 0xffffffff, DA_DRW
LABEL_DESC_LDT:         SegDesc 0, LdtLimit, DA_LDT

GdtLen = . - LABEL_GDT

GdtPtr:
    .word GdtLen - 1
    .long LABEL_GDT

.p2align 2
LABEL_LDT:          SegDesc 0, 0, 0
LABEL_DESC_LCODE:   SegDesc 0, 0xffffffff, DA_CR | DA_32
LABEL_DESC_LDATA:   SegDesc 0, 0xffffffff, DA_32 | DA_DRW
LdtLimit = . - LABEL_LDT - 1

msgr:
    .ascii "real: hello world!"
msgrlen:
    .word  . - msgr

msgg:
    .ascii "prodect: gdt: hello world!"
msgglen:
    .word  . - msgg

msgl:
    .ascii "prodect: ldt: hello world!"
msgllen:
    .word  . - msgl

.word 100

.org 510
    .word 0xAA55
