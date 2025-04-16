// commannd_f.c -- 'F' command implement, FDC/DMA C subroutines for MiniMon

#include <stdio.h>
#include <string.h>

static char buf[ 256 ];

//functions
void *
Command_F_getBuffer()
{
//    sprintf(buf, "dummy");
    return (void *)&buf;   // return global pointer
}

