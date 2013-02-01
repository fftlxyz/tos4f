static __inline void
outb(int port, uint8_t data)
{
    __asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
}


static __inline uint8_t
inb(int port)
{
    uint8_t data;
    //内联汇编 不优化
    //inb
    //%w1 第一个操作数的低word字节
    //%0  第0个操作书
    //=a 输出参数，a EAX
    //d 输入参数, d edx
    __asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
    return data;
}

static __inline void
insl(int port, void *addr, int cnt)
{
    __asm __volatile("cld\n\trepne\n\tinsl":
            "=D" (addr), "=c" (cnt):
            //----------与第i个操作数匹配
            "d" (port), "0" (addr), "1" (cnt):
            //will change memory, condition code
            //clobber list
            "memory", "cc");
}
