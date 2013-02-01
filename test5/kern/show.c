
void cputs(char *str);
void cputint(int i);
void cputchar(char ch);
void ccls();
void setshowpos(int showpos);
int getshowpos();

//返回字符串长度
int showstr(char *str, int pos);

static int pos = 0;
int width = 80;
int height = 25;

void ccls()
{
    char *strnull = "                                                                              ";
    int i ;
    for (i = 0; i < 24; ++i) {
        showstr(strnull,i*80);
    }

    pos = 0;
}

void cputs(char *str)
{
    pos += showstr(str, pos);
    pos = pos % (width * height);
}

void cputchar(char ch)
{
    char buf[2] = {0};
    buf[0] = ch;
    buf[1] = 0;

    pos += showstr(buf, pos);
    pos = pos % (width * height);
}

void cputint(int i)
{
    char buf[16] = {0};
    char stk[16];
    char ch;
    int top = 0;
    int ibuf;

    buf[0] = '0';
    buf[1] = 'x';


    while(i / 16) {
        ch = i % 16 ;
        if ( ch < 10) {
            ch += '0';
        } else {
            ch += 'A' - 10;
        }
        stk[top++] = ch;
        i = i/16;
    }

    ch = i % 16 ;
    if ( ch < 10) {
        ch += '0';
    } else {
        ch += 'A' - 10;
    }

    stk[top++] = ch;

    while (top < 8) {
        stk[top++] = '0';
    }

    ibuf = 2;
    while( top > 0 ) {
        buf[ibuf++] = stk[--top];
    }

    pos += showstr(buf, pos);
    pos = pos % (width * height);
}

int getshowpos()
{
    return pos;
}

void setshowpos(int showpos)
{
    pos = showpos;
}

void clr()
{
    pos = ((pos / 80) + 1) * 80;
    pos = pos % (width * height);
}
