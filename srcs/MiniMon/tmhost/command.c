// command.c

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "control.h"
#include "parse.h"
#include "command.h"

extern uint8_t *Buf_Memory;
extern char Buf_Mes[ 80 ];
//
extern uint16_t DestAddr;
extern uint16_t DownUpLength;
extern uint8_t Wm64[ 64 ];
extern uint8_t Wm64_Size;
extern uint8_t Wm01;
extern bool F_Break;
extern uint16_t BreakPoint;
extern bool F_Trace;


char Buf_Cons[ 80 ];

void cmd_Help( void );
void cmd_AltBreakPoint( void );
void cmd_SetBreakPoint( void );
void ucase( void );

void ucase_Buf_Cons()
{
    uint8_t count = 0;

    while( 1 )
    {
        if( Buf_Cons[ count ] == NUL )
        {
            break;
        }
        if( Buf_Cons[ count ] >= 'a' && Buf_Cons[ count ] <= 'z' )
        {
            Buf_Cons[ count ] = Buf_Cons[ count ] - 'a' + 'A';
        }
        count++;
    }
}

int16_t Command()
{
    fprintf( stderr, "tmhost:>>> " );
    fgets( Buf_Cons, sizeof( Buf_Cons ), stdin );
    ucase_Buf_Cons();

    switch( Buf_Cons[ 0 ] )
    {
        case 'H':
            cmd_Help();
            break;
        case 'Q':
            return -32767;
        case 'D':
            break;
        case 'U':
            break;
        case 'L':
            break;
        case 'S':
            break;
        case 'B':
            if( Buf_Cons[ 1 ] == 'S' )
            {
                cmd_SetBreakPoint();
            }
            else
            {
                cmd_AltBreakPoint();
            }
            return SET_BP;
        default:
            break;
    }

    return -1;
}

void cmd_Help()
{
    fprintf( stderr, "tmhost: Command Help\n" );
    fprintf( stderr, "H: Help(dump this text)\n" );
    fprintf( stderr, "Q: Exit\n\n" );
    fprintf( stderr, "L/S {filename}: Load/Save memory buffer\n" );
//    fprintf( stderr, "LL {filename}: Load Listing file\n" );
    fprintf( stderr, "\n" );
    fprintf( stderr, "D/U: Download/Upload binary to the Target\n" );
//    fprintf( stderr, "M {addr}: Modify memory on the Target\n" );
//    fprintf( stderr, "I/O {addr}: Inport/Outport data on the Target\n" );
    fprintf( stderr, "\n" );
//    fprintf( stderr, "E {addr}: Edit Host memory buffer\n" );
//    fprintf( stderr, "\n" );
    fprintf( stderr, "B : Alternate(On/Off) BreakPoint\n" );
    fprintf( stderr, "BS {addr}: Set BreakPoint\n" );
//    fprintf( stderr, "R {addr}: Run Target program\n" );
//    fprintf( stderr, "T {addr}: Trace Target program(EXPERIMENTAL)\n" );
    fprintf( stderr, "\n" );
}

void cmd_AltBreakPoint()
{
    if( F_Break == true )
    {
        fprintf( stderr, "tmhost: Reset BreakPoint\n" );
        F_Break = false;
    }
    else
    {
        fprintf( stderr, "tmhost: Set BreakPoint\n" );
        F_Break = true;
    }
}

void cmd_SetBreakPoint()
{
    char buf[ 10 ];

    if( Buf_Cons[ 2 ] == ' ' && Buf_Cons[ 3 ] != NUL )
    {
        uint8_t loop = 0;
        while( 1 )
        {
            if( Buf_Cons[ loop ] != NUL )
            {
                buf[ loop ] = Buf_Cons[ loop + 2 ];
                loop++;
            }
            else
            {
                break;
            }
        }
    }
    else
    {
        fprintf( stderr, "tmhost: BreakPoint Addr. > " );
        fgets( buf, sizeof( buf ), stdin );
    }
    BreakPoint = strtoll( buf, NULL, 16 );
    fprintf( stderr, "tmhost: BreakPpoint at 0x%04X\n", BreakPoint );
}
