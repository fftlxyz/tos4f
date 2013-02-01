#include "mmu.h"

.set PROT_MODE_CSEG, 0x8
.set PROT_MODE_DSEG, 0x10
.set PROT_MODE_LDT, 0x18
.set CR0_PE_ON, 0x1

.set PROT_MODE_CSEG_LOCAL, 0x8 | 0x04
.set PROT_MODE_DSEG_LOCAL, 0x10 | 0x04

.globl start

start:

.code16
    cli
    cld

    xorw %ax, %ax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %ss


    movw $0xb800, %ax
    movw %ax, %es
    movw $msg1, %si
    movw $0xc82, %di
    movw $8, %cx
    rep movsb


    movw $str, %si
    movw $0xc94, %di
    movw $26, %cx
    rep movsb


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

    //mov ldt, %ax
    //movw %ax, (ldtdesc+ 2)

    lgdt gdtdesc
    movl %cr0, %eax
    orl $CR0_PE_ON, %eax
    movl %eax, %cr0

    ljmp $PROT_MODE_CSEG, $protcseg

    .code32
protcseg:
    
    movw $PROT_MODE_DSEG, %ax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %fs
    movw %ax, %gs
    movw %ax, %ss

    movl $msg2, %esi
    movl $0xb8d22, %edi
    movl $18, %ecx
    rep movsb

    movl $str, %esi
    movl $26, %ecx
    rep movsb


    mov $PROT_MODE_LDT, %ax
    lldt %ax

    ljmp $PROT_MODE_CSEG_LOCAL, $localcode


localcode:

    movw $PROT_MODE_DSEG_LOCAL, %ax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %fs
    movw %ax, %gs
    movw %ax, %ss

    movl $msg3, %esi
    movl $0xb8dc2, %edi
    movl $52, %ecx
    rep movsb

spin:
    jmp spin

.p2align 2
gdt:
    SEG_NULL
    SEG(STA_X | STA_R, 0x0, 0xffffffff)
    SEG(STA_W, 0x0, 0xffffffff)
ldtdesc:
    .word 0x40, ldt, 0x8200, 0x0
    //SEG(STS_LDT, ldt, 0xffffffff)

gdtdesc:
    .word 0x1f
    .long gdt

.p2align 2
ldt:
    SEG_NULL
    SEG(STA_X | STA_R, 0x0, 0xffffffff)
    SEG(STA_W, 0x0, 0xffffffff)


msg1:
.byte 'r',0xc,'e',0xc,'a',0xc,'l',0xc

msg2:
.byte 'p',0xc,'r',0xc,'o',0xc,'t',0xc,'e',0xc,'c',0xc,'t',0xc,'e',0xc,'d',0xc

msg3:
.byte 'p',0xc,'r',0xc,'o',0xc,'t',0xc,'e',0xc,'c',0xc,'t',0xc,'e',0xc,'d',0xc,':',0xc,'l',0xc,'d',0xc,'t', 0xc

str:
.byte ':',0xc,' ',0xc,'h',0xc,'e',0xc,'l',0xc,'l',0xc,'o',0xc,' ',0xc,'w',0xc,'o',0xc,'r',0xc,'l',0xc,'d',0xc

.org 510
    .word 0xAA55
