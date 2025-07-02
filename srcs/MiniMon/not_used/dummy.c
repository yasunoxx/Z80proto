// dummy.c

#include <stdio.h>
#include <string.h>

static char buf[80];

void *dummy()
{
    int dummy2 = 0;
//    sprintf(buf, "dummy");
    return (void *)&buf;   // return global pointer
}

int sprit_buf()
{
    size_t val = 0;
    val = strtok( buf, " " );
    return (int)val;   // return length ... ?
}
