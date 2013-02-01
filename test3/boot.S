# ring0 -> ring3 , ring3 call ring0 via call gate
.include "pm.inc"

.set GCODE_SEL , 0x8
.set GDATA_SEL , 0x10
.set SCRN_SEL , 0x18
.set LDT_SEL , 0x20
.set RING0_STK_SEL, 0x28
.set CALL_SHOW_MSG_SEL, 0x30 | SA_RPL3
.set TSS_SEL, 0x38

.set LCODE_SEL, 0x8 | SA_TIL | SA_RPL3
.set LDATA_SEL, 0x10 | SA_TIL | SA_RPL3
.set LSS_SEL, 0x18 | SA_TIL | SA_RPL3

.globl start

start:
.code16

    cli

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
#  i am out of space ... so...
LABEL_STK_RING0:

    movw $0, %ax
    movw %ax, %ds
    lgdt GdtPtr

    # setup ldt in gdt
    mov $LABEL_DESC_LDT, %edi
    movw $LABEL_LDT, 2(%edi)

    # set up ldt code
    mov $LABEL_DESC_LCODE, %edi
    movw $LABEL_LCODE, 2(%edi)

    mov $LABEL_DESC_RING0SS, %edi
    movw $LABEL_STK_RING0, 2(%edi)

    mov $LABEL_DESC_TSS, %edi
    movw $LABEL_TSS, 2(%edi)

    mov $LABEL_DESC_CALL_SHOW_MSG, %edi
    movw $ShowMsg, (%edi)
    movw $GCODE_SEL, 2(%edi)

    #启用分段
    movw $0x0001, %ax
    lmsw %ax

    #figure out why $, and jmp not
    ljmp $GCODE_SEL, $LABEL_GCODE
    #ljmp $0x1, $0x2
# i am out of space .. so
LABEL_STK_RING3:

.code32
LABEL_GCODE:

    movw $GDATA_SEL, %ax
    movw %ax, %ds

    lss StkRing0, %esp

    movw $GDATA_SEL, %ax
    movw %ax, %ds

    movb $21, %bh
    movw $msgr0, %si
    movw msgr0len, %cx

    lcall $CALL_SHOW_MSG_SEL, $0

    movw $LDT_SEL, %ax
    lldt %ax

    movw $TSS_SEL, %ax
    ltr %ax

    pushl $LSS_SEL
    pushl $0
    pushl $LCODE_SEL
    pushl $0
    #pushl $LABEL_LCODE
    lret

    #ljmp $LCODE_SEL, $LABEL_LCODE

# bh row, si, msg, cx msglen
ShowMsg:

    movw $SCRN_SEL, %ax
    movw %ax, %es
    xorl %eax, %eax
    movb %bh, %al
    movb $160, %ah
    mulb %ah
    movw %ax, %di
1:
    cmpw $0x0, %cx
    jz  1f
    dec %cx
    movb (%si), %al
    movb %al, %es:(%di)
    inc %di
    movb $0xc, %es:(%di)
    inc %di
    inc %si
    jmp 1b
1:
    lret

LABEL_LCODE:

    movw $LDATA_SEL, %ax
    movw %ax, %ds

    lss StkRing3, %esp

    movb $22, %bh
    movw $msgr3, %si
    movw msgr3len, %cx

    lcall $CALL_SHOW_MSG_SEL, $0

    jmp .

.p2align 2

LABEL_GDT:              SegDesc 0, 0, 0
LABEL_DESC_GCODE:       SegDesc 0, 0xffffffff, DA_CR | DA_32
LABEL_DESC_GDATA:       SegDesc 0, 0xffffffff, DA_32 | DA_DRW
LABEL_DESC_SCRN:        SegDesc 0xb8000, 0xffffffff, DA_DRW
LABEL_DESC_LDT:         SegDesc 0, LdtLimit, DA_LDT
LABEL_DESC_RING0SS:     SegDesc 0, 0xffff,  DA_32 | DA_DRW
LABEL_DESC_CALL_SHOW_MSG: Gate 0, 0, 0,  DA_386CGat | DA_DPL3
LABEL_DESC_TSS:         SegDesc 0, TSSLimit , DA_386TS

GdtLen = . - LABEL_GDT

GdtPtr:
    .word GdtLen - 1
    .long LABEL_GDT

.p2align 2
LABEL_LDT:          SegDesc 0, 0, 0
LABEL_DESC_LCODE:   SegDesc 0, 0xffffffff, DA_CR | DA_32 | DA_DPL3
LABEL_DESC_LDATA:   SegDesc 0, 0xffffffff, DA_32 | DA_DRW | DA_DPL3
LABEL_DESC_RING3SS:      SegDesc 0, 0xffff, DA_32 | DA_DRW | DA_DPL3
LdtLimit = . - LABEL_LDT - 1

StkRing0:
    .long LABEL_STK_RING0
    .word GDATA_SEL

StkRing3:
    .long LABEL_STK_RING3
    .word LDATA_SEL

.p2align 2
LABEL_TSS:
    .long   0           # Back
    .long   LABEL_STK_RING0     # 0 级堆栈
    .long   RING0_STK_SEL       #
    .long   0           # 1 级堆栈
    .long   0           # 
    .long   0           # 2 级堆栈
    .long   0           # 
    .long   0           # CR3
    .long   0           # EIP
    .long   0           # EFLAGS
    .long   0           # EAX
    .long   0           # ECX
    .long   0           # EDX
    .long   0           # EBX
    .long   0           # ESP
    .long   0           # EBP
    .long   0           # ESI
    .long   0           # EDI
    .long   0           # ES
    .long   0           # CS
    .long   0           # SS
    .long   0           # DS
    .long   0           # FS
    .long   0           # GS
    .long   0           # LDT
    .word   0           # 调试陷阱标志
    .word   . - LABEL_TSS + 2   # I/O位图基址
    .byte   0xff           # I/O位图结束标志
TSSLimit = . - LABEL_TSS -1

msgr0:
    .ascii "p:r0!"
msgr0len:
    .word  . - msgr0


msgr3:
    .ascii "p:r3!"
msgr3len:
    .word  . - msgr3

#.org 510
#    .word 0xAA55
