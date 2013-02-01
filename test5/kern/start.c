
#include <inc/mmu.h>
#include <inc/x86.h>
#include <inc/trap.h>

#define GDT_SIZE 256
#define IDT_SIZE 256
#define LDT_SIZE 256

#define INT_M_CTL0 0x20
#define INT_M_CTL1 0x21
#define INT_S_CTL0 0xA0
#define INT_S_CTL1 0xA1

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

void setshowpos(int showpos);
int getshowpos();
void cputs(char *str);
void cputint(int i);
void cputchar(char ch);
void ccls();
void clr();

void idtdefaluthandler();

void task0();
void task1();

void diverr();
void dbgexcep();
void nmi();
void bktptexcep();
void overflow();
void boundscheck();
void invalopcode();
void devicenotavail();
void doublefault();
void tssexcep();
void segnotprsnt();
void stkexcep();
void generalprocexcep();
void pagefault();
void fpgerr();
void alignerror();

void irq00();
void irq01();
void irq02();
void irq03();
void irq04();
void irq05();
void irq06();
void irq07();
void irq08();
void irq09();
void irq10();
void irq11();
void irq12();
void irq13();
void irq14();
void irq15();

void init8259();
void init8253();
void setupidt();
void setupldt();
void setupgdt();
void delay();
void inittask();

struct Segdesc gdt[GDT_SIZE] = {0};
struct Segdesc ldt[LDT_SIZE] = {0};
struct Segdesc idt[IDT_SIZE] = {0};

struct Taskstate task[2] = {0};

struct Pseudodesc  pdgdt= {0};
struct Pseudodesc pdidt= {0};

int itask = 0;

void kerninit()
{
    init8259();
    init8253();
    setupldt();
    setupgdt();
    inittask();
    setupidt();

    lgdt(&pdgdt);
    lldt(SEL_LDT);
    ltr(SEL_TASK0);
    lidt(&pdidt);

    ccls();
}



void setupgdt()
{
    int i;

    pdgdt.pd_lim = GDT_SIZE * sizeof(struct Segdesc) - 1;
    pdgdt.pd_base = (int)gdt;

    gdt[0] = SEG_NULL;
    gdt[1] = SEG(STA_X, 0, 0xffffffff,0);
    gdt[2] = SEG(STA_W, 0, 0xffffffff,0);
    gdt[3] = SEG(STA_W, 0xb8000, 0xffffffff,3);

    gdt[4] = SEG(STS_LDT, (int)ldt, (LDT_SIZE * sizeof(struct Segdesc) - 1), 0);
    gdt[4].sd_s = 0;

    gdt[5] = SEG(STS_T32A, (int)(task), sizeof(struct Taskstate) - 1, 0);
    gdt[5].sd_s = 0;

    gdt[6] = SEG(STS_T32A, (int)(task + 1), sizeof(struct Taskstate) - 1, 0);
    gdt[6].sd_s = 0;

    for (i = 7; i < GDT_SIZE; ++i) {
        gdt[i] = SEG_FAULT;
    }

}


int task0r3stk[1024];
int task0r0stk[1024];
int task1r3stk[1024];
int task1r0stk[1024];

void setupldt()
{
    int i;

    ldt[0] = SEG_NULL;

    ldt[1] = SEG(STA_X, 0, 0xffffffff,3); //task0 cs
    ldt[2] = SEG(STA_W, 0, 0xffffffff,3); //task0 ds

    ldt[3] = SEG(STA_X, 0, 0xffffffff,3); //task0 cs
    ldt[4] = SEG(STA_W, 0, 0xffffffff,3); //task0 ds

    /* ldt[3] = SEG16(STA_E | STA_W, (int)((char *)task0r0stk + sizeof(task0r0stk)),(int)(task0r0stk), 0); //task0 ring0 stack */
    /* ldt[4] = SEG16(STA_E | STA_W, (int)((char *)task0r3stk + sizeof(task0r3stk)),(int)(task0r3stk), 3); //task0 ring3 stack */

    for( i = 5; i < LDT_SIZE; ++i) {
        ldt[i] = SEG_FAULT;
    }
}

void inittask()
{
    task[0].ts_ss0 = SEL_KERN_DS;
    task[0].ts_esp0 = (int)task0r0stk + sizeof(task0r0stk);

    task[1].ts_ss0 = SEL_KERN_DS;
    task[1].ts_esp0 = (int)task0r0stk + sizeof(task1r0stk);
    /* task[1].ts_cs = SEL_TASK1_CS; */
    /* task[1].ts_eip = (int)task1; */
    /* task[1].ts_eflags = 0x3202; */
    /* task[1].ts_ds = SEL_TASK1_DS; */
    /* task[1].ts_ss = SEL_TASK1_DS; */
}

void setupidt()
{
    int i;

    pdidt.pd_lim = IDT_SIZE * sizeof(struct Segdesc) -1;
    pdidt.pd_base = (int)idt;

    for ( i = 0; i < IDT_SIZE; ++i) {
        SETGATE( *(struct Gatedesc*)(&idt[i]), 0, SEL_KERN_CS, idtdefaluthandler, 0);
    }

    SETGATE( *(struct Gatedesc*)(&idt[T_DIVIDE]), 0, SEL_KERN_CS, diverr, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_DEBUG]), 0, SEL_KERN_CS, dbgexcep, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_NMI]), 0, SEL_KERN_CS, nmi, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_BRKPT]), 0, SEL_KERN_CS, bktptexcep, 3);
    SETGATE( *(struct Gatedesc*)(&idt[T_OFLOW]), 0, SEL_KERN_CS, overflow, 3);
    SETGATE( *(struct Gatedesc*)(&idt[T_BOUND]), 0, SEL_KERN_CS, boundscheck, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_ILLOP]), 0, SEL_KERN_CS, invalopcode, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_DEVICE]), 0, SEL_KERN_CS, devicenotavail, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_DBLFLT]), 0, SEL_KERN_CS, doublefault, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_TSS]), 0, SEL_KERN_CS, tssexcep, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_SEGNP]), 0, SEL_KERN_CS, segnotprsnt, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_STACK]), 0, SEL_KERN_CS, stkexcep, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_GPFLT]), 0, SEL_KERN_CS, generalprocexcep, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_PGFLT]), 0, SEL_KERN_CS, pagefault, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_FPERR]), 0, SEL_KERN_CS, fpgerr, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_ALIGN]), 0, SEL_KERN_CS, alignerror, 0);

    SETGATE( *(struct Gatedesc*)(&idt[T_INT_IRQ0]), 0, SEL_KERN_CS, irq00, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_INT_IRQ0 + 1]), 0, SEL_KERN_CS, irq01, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_INT_IRQ0 + 2]), 0, SEL_KERN_CS, irq02, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_INT_IRQ0 + 3]), 0, SEL_KERN_CS, irq03, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_INT_IRQ0 + 4]), 0, SEL_KERN_CS, irq04, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_INT_IRQ0 + 5]), 0, SEL_KERN_CS, irq05, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_INT_IRQ0 + 6]), 0, SEL_KERN_CS, irq06, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_INT_IRQ0 + 7]), 0, SEL_KERN_CS, irq07, 0);

    SETGATE( *(struct Gatedesc*)(&idt[T_INT_IRQ8]), 0, SEL_KERN_CS, irq08, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_INT_IRQ8 + 1]), 0, SEL_KERN_CS, irq09, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_INT_IRQ8 + 2]), 0, SEL_KERN_CS, irq10, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_INT_IRQ8 + 3]), 0, SEL_KERN_CS, irq11, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_INT_IRQ8 + 4]), 0, SEL_KERN_CS, irq12, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_INT_IRQ8 + 5]), 0, SEL_KERN_CS, irq13, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_INT_IRQ8 + 6]), 0, SEL_KERN_CS, irq14, 0);
    SETGATE( *(struct Gatedesc*)(&idt[T_INT_IRQ8 + 7]), 0, SEL_KERN_CS, irq15, 0);

    /* SETGATE( *(struct Gatedesc*)(&idt[T_]), 0, SEL_KERN_CS,, 0); */
}


void init8259()
{
     //ICW1
     outb(INT_M_CTL0, 0x11);
     delay();
     //ICW2
     outb(INT_M_CTL1, T_INT_IRQ0);
     delay();
     //ICW3
     outb(INT_M_CTL1, 0x4);
     delay();
     //ICW4
     outb(INT_M_CTL1, 0x1);
     delay();
     //OCW1
     outb(INT_M_CTL1, 0x0);
     delay();

     //ICW1
     outb(INT_S_CTL0, 0x11);
     delay();
     //ICW2
     outb(INT_S_CTL1, T_INT_IRQ8);
     delay();
     //ICW3
     outb(INT_S_CTL1, 0x2);
     delay();
     //ICW4
     outb(INT_S_CTL1, 0x1);
     delay();
     //OCW1
     outb(INT_S_CTL1, 0x00);
     delay();
}

void delay()
{
    int i = 0;

    for (i =0; i < 10; ++i) {
        __asm__ __volatile("nop\n\t");
    }
}


void excephandler(int vecno, int errcode, int eip, int cs, int eflags)
{
    char* errmsg[] = {
        "divide error",
        "debug exception",
        "non-maskable interrupt",
        "breakpoint",
        "overflow",
        "bounds check",
        "illegal opcode",
        "device not available",
        "double fault",
        "reserved (not generated by recent processors)",
        "invalid task switch segment",
        "segment not present",
        "stack exception",
        "general protection fault",
        "page fault",
        "reserved",
        "floating point error",
        "aligment check",
        "machine check",
        "SIMD floating point error"
    };

    cputs("vecno:");
    cputint(vecno);
    cputs(" ");
    cputs(errmsg[vecno]);
    clr();
    cputs("eip:");
    cputint(eip);
    cputs(" ");
    cputs("cs:");
    cputint(cs);
    cputs(" ");
    cputs("eflags:");
    cputint(eflags);
    cputs(" ");
    clr();

    if(errcode != 0xffffffff) {
        cputs("errcode:");
        cputint(errcode);
    }
}

static int irqi = 0;
void irqhandler(int irq)
{
    __asm __volatile("movw %w0, %%ds" : : "r" (SEL_KERN_DS) :);


    /* cputs("irq:"); */
    /* cputint(irq); */
    /* cputs("  "); */
    /* cputint(irqi++); */
    /* clr(); */

    /* 写eoi */
    int port = INT_M_CTL0;
    if (irq > 8)
        port = INT_S_CTL0;
    outb( port, 0x20);
    outb( INT_M_CTL0, 0x20);
}



void init8253()
{
    int latch = 11930;
    /* latch = 65536; */
    outb(0x43,0x36);

    outb(0x40,latch);
    outb(0x40,latch>>8);
}


void task0()
{
    __asm __volatile("movw %w0, %%ds" : : "r" (SEL_TASK0_DS) :);
    int count = 0;
    while (1) {
        cputchar('A');
        cputint(count++);
        int i = 0;
        for ( i = 0; i < 100000; ++i)
            delay();
    }
}

void task1()
{
    __asm __volatile("movw %w0, %%ds" : : "r" (SEL_TASK1_DS) :);
    int count = 0;
    while (1) {
        cputchar('B');
        cputint(count++);
        int i = 0;
        for ( i = 0; i < 100000; ++i)
            delay();
    }
}
