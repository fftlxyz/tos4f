#include <inc/trap.h>
.include "inc/pm.inc"


#define SEG_SEL_RPL3 0x3

#define SEL_KERN_CS 0x8
#define SEL_KERN_DS 0x10
#define SEL_SCRN (0x18 | SEG_SEL_RPL3)
#define SEL_LDT 0x20
#define SEL_TASK0 0x28
#define SEL_TASK1 0x30

#define SEG_SEL_TI_LDT 0x4
#define SEL_TASK0_CS (0x8 | SEG_SEL_TI_LDT | SEG_SEL_RPL3 )
#define SEL_TASK0_DS (0x10 | SEG_SEL_TI_LDT | SEG_SEL_RPL3 )
#define SEL_TASK1_CS (0x18 | SEG_SEL_TI_LDT | SEG_SEL_RPL3 )
#define SEL_TASK1_DS (0x20 | SEG_SEL_TI_LDT | SEG_SEL_RPL3 )

.globl idtdefaluthandler
.globl start
.globl showstr
.globl diverr
.globl dbgexcep
.globl nmi
.globl bktptexcep
.globl overflow
.globl boundscheck
.globl invalopcode
.globl devicenotavail
.globl doublefault
.globl tssexcep
.globl segnotprsnt
.globl stkexcep
.globl generalprocexcep
.globl pagefault
.globl fpgerr
.globl alignerror
.globl irq00
.globl irq01
.globl irq02
.globl irq03
.globl irq04
.globl irq05
.globl irq06
.globl irq07
.globl irq08
.globl irq09
.globl irq10
.globl irq11
.globl irq12
.globl irq13
.globl irq14
.globl irq15

.p2align 3
.code32
start:

    movw $0x10, %ax
    movw %ax, %ds

    call kerninit

    ljmp $SEL_KERN_CS, $csinit
csinit:
    sti

    movw $SEL_KERN_DS, %ax
    movw %ax, %ds

    lss StkRing0, %esp

    movw $SEL_KERN_DS, %ax
    movw %ax, %ds

    # jmp .
    #
    #

    movw $SEL_KERN_DS, %dx
    movw %dx, %ss

    movl $task1r0stk + 1024*4, %esp
    pushl $SEL_TASK1_DS 
    pushl $task1r3stk + 1024*4
    pushl $0x3202
    pushl $SEL_TASK1_CS
    pushl $task1
    pusha
    pushw $SEL_TASK1_DS 
    pushw $SEL_TASK1_DS 
    pushw $SEL_TASK1_DS 
    pushw $SEL_TASK1_DS 

    movl $task0r0stk + 1024*4, %esp
    pushl $SEL_TASK0_DS 
    pushl $task0r3stk + 1024*4
    pushl $0x3202
    pushl $SEL_TASK0_CS
    pushl $task0
    iret


    # pushl $SEL_TASK0_DS
    # pushl $task0r3stk+1024*4
    # pushl $SEL_TASK0_CS
    # pushl $task0
    # ret


    # int $0x20
    # int $0x21
    # int $0x22
    # int $0x23
    # int $0x24
    # int $0x25
    # int $0x26
    # int $0x27
    # int $0x28
    # int $0x29
    # int $0x2a
    # int $0x2b
    # int $0x2c
    # int $0x2d
    # int $0x2e
    # int $0x2f

    # jmp diverr

    # movl $0, %eax
    # div %ax

    # ljmp $0x40, $0
    #
    jmp .

#showstr(char *str, int pos)
showstr:
    push %ebp
    mov %esp, %ebp

    push %ebx
    push %ecx
    push %edx
    push %es
    push %esi
    push %edi

    mov 12(%ebp), %bx
    mov 8(%ebp), %si

    movw $SEL_SCRN, %ax
    movw %ax, %es

    sal %bx
    movw %bx, %di
    xor %eax, %eax
1:
    cmpb $0x0, (%si)
    jz  1f
    inc %eax
    movb (%si), %dl
    movb %dl, %es:(%di)
    inc %di
    movb $0xc, %es:(%di)
    inc %di
    inc %si
    jmp 1b
1:
    pop %edi
    pop %esi
    pop %es
    pop %edx
    pop %ecx
    pop %ebx
    pop %ebp

    ret


.p2align 4
diverr:
    pushl $0xffffffff
    pushl $T_DIVIDE
    jmp exception

.p2align 4
dbgexcep:
    pushl $0xffffffff
    pushl $T_DEBUG
    jmp exception

.p2align 4
nmi:
    pushl $0xffffffff
    pushl $T_NMI
    jmp exception

.p2align 4
bktptexcep:
    pushl $0xffffffff
    pushl $T_BRKPT
    jmp exception

.p2align 4
overflow:
    pushl $0xffffffff
    pushl $T_OFLOW
    jmp exception

.p2align 4
boundscheck:
    pushl $0xffffffff
    pushl $T_BOUND
    jmp exception

.p2align 4
invalopcode:
    pushl $0xffffffff
    pushl $T_ILLOP
    jmp exception

.p2align 4
devicenotavail:
    pushl $0xffffffff
    pushl $T_DEVICE
    jmp exception

.p2align 4
doublefault:
    pushl $T_DBLFLT
    jmp exception

.p2align 4
tssexcep:
    pushl $T_TSS
    jmp exception

.p2align 4
segnotprsnt:
    pushl $T_SEGNP
    jmp exception

.p2align 4
stkexcep:
    pushl $T_STACK
    jmp exception

.p2align 4
generalprocexcep:
    pushl $T_GPFLT
    jmp exception

.p2align 4
pagefault:
    pushl $T_PGFLT
    jmp exception

.p2align 4
fpgerr:
    pushl $0xffffffff
    pushl $T_FPERR
    jmp exception

.p2align 4
alignerror:
    pushl $0xffffffff
    pushl $T_ALIGN
    jmp exception

exception:
    call excephandler
    add $8, %esp
    hlt

.p2align 4
irq00:
    pusha
    pushw %ds
    pushw %es
    pushw %fs
    pushw %gs

    movw %ss, %dx
    movw %dx, %ds

    pushl $0
    call irqhandler
    add $4, %esp

    cmpl  $0, itask
    jnz 1f
    mov $task0r0stk + 1024*4 - 20 - 32 - 8, %esp
    movl $task0r0stk + 1024*4, task + 4
    # mov $SEL_TASK0, %ax
    # ltr %ax
    movl $1, itask
    jmp 0f
1:
    mov $task1r0stk + 1024*4 - 20 - 32 - 8, %esp
    movl $task1r0stk + 1024*4, task + 4
    # mov $SEL_TASK1, %ax
    # ltr %ax
    movl $0, itask
0:
    popw %gs
    popw %fs
    popw %es
    popw %ds
    popa

    iret

.p2align 4
irq01:
    pushl $1
    call irqhandler
    add $4, %esp
    iret

.p2align 4
irq02:
    pushl $2
    call irqhandler
    add $4, %esp
    iret

.p2align 4
irq03:
    pushl $3
    call irqhandler
    add $4, %esp
    iret

.p2align 4
irq04:
    pushl $4
    call irqhandler
    add $4, %esp
    iret

.p2align 4
irq05:
    pushl $5
    call irqhandler
    add $4, %esp
    iret

.p2align 4
irq06:
    pushl $6
    call irqhandler
    add $4, %esp
    iret

.p2align 4
irq07:
    push $7
    call irqhandler
    add $4, %esp
    iret

.p2align 4
irq08:
    push $8
    call irqhandler
    add $4, %esp
    iret

.p2align 4
irq09:
    push $9
    call irqhandler
    add $4, %esp
    iret

.p2align 4
irq10:
    push $10
    call irqhandler
    add $4, %esp
    iret

.p2align 4
irq11:
    push $11
    call irqhandler
    add $4, %esp
    iret

.p2align 4
irq12:
    push $12
    call irqhandler
    add $4, %esp
    iret

.p2align 4
irq13:
    push $13
    call irqhandler
    add $4, %esp
    iret

.p2align 4
irq14:
    push $14
    call irqhandler
    add $4, %esp
    iret

.p2align 4
irq15:
    push $15
    call irqhandler
    add $4, %esp
    iret

.p2align 2
idtdefaluthandler:
    push $msgidthandler
    call cputs
    add $4, %esp
    iret

.fill 100,4, 0
LABEL_STK_RING0:

StkRing0:
    .long LABEL_STK_RING0
    .word SEL_KERN_DS

.fill 100,4, 0
LABEL_STK_RING3:

msgr0:
    .ascii "protected:ring0!\0"

msgr3:
    .ascii "protected:ring3!\0"
msgidthandler:
    .ascii "idt     \0"
