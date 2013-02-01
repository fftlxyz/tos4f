tiny os for fun

project description:

test1
after boot, print a msg;
when jump to protected mode, print another msg.
then spin.

test2
based on test1, but print another msg use ldt.

test2u
based on test2, u means updated.
对代码进行了整理

test3
based on test3, but i jump to ring3 to print another msg.

test4
写了loader，用来加载kernel.
在test3中，512byte 不太够用了.
效果和test3是一样的.

test5
加了中断处理，然后实现了简单的两个任务的切换。
交替打印字母.

以后，我会用git来管理的代码.  
我打算做一个简单的os, 准备采用采用宏内核的架构...
just for fun.. 

ps: 可能你已经看出来了，我参考了 orange's, 一个操作系统的实现 这本书.
    我的代码组织形式也是仿着那本书的.
    不过我也从 joes 中借鉴了一部分代码.
