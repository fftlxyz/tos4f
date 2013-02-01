
#include <inc/mmu.h>


int main(int argc, const char *argv[])
{
    printf("%d\n",sizeof(struct Taskstate));
    printf("%d\n",&((struct Taskstate*)0)->ts_esp0);
    printf("%d\n",&((struct Taskstate*)0)->ts_ss0);
    printf("%d\n",&((struct Taskstate*)0)->ts_eip);
    printf("%d\n",&((struct Taskstate*)0)->ts_cs);
    printf("%d\n",&((struct Taskstate*)0)->ts_eflags);

    return 0;
}
