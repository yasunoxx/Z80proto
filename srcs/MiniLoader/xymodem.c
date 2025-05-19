// xymodem.c -- Kerm... XYMODEM/CRC C implement
// Program 2025 by yasunoxx▼Julia

// original copyright:
/*
    X/YMODEM Copyright 1982-88 by Ward Christensen
*/

#define NUL 0
#define SOH 1
#define STX 2
#define EOT 4
#define ACK 6
#define NAK 0x15
#define CAN 0x18
#define CHR_C   0x43
#define SPC 32
#define CPMEOF  28
#define CR  13
#define LF  11
#define DEL 127

#define SECOND 2    // SlowTick increment 500msec/count

#include <stdint.h>
#include <stdbool.h>

uint8_t TxBuf[ 64 ], RxBuf[ 1034 ];
uint8_t Serial, CRCH, CRCL;
uint16_t CRC;

#if defined evLPC2388 || defined evADuC7129
#include "lpc2300.h"
#include "uart.h"
extern volatile uint16_t vic_SlowTick;
#define SlowTick vic_SlowTick
#define _NOP() LCD_NOP()
#define USE_LCD 1
#define LCD_initIO()
#else   // Z80proto
void _NOP()
{
#asm
    nop
#endasm
}
extern volatile uint16_t SlowTick;
extern  uint16_t getchar_SIO0( void );
extern  void putchar_SIO0( uint8_t );
extern  void puts_SIO0( uint8_t * );
#define uart0_getc()    getchar_SIO0()
#define uart0_putc(x)   putchar_SIO0(x)
#define USE_LCD 1
#define LCD_initIO() DEBUG_PPIOUT_SETUP()
#endif

#if USE_LCD
#include "xprintf.h"
#include "lcd1602.h"
#endif

void xymodem_init( void );
uint8_t xymodem_receive( uint16_t );   // act receiving w/timeout
uint8_t xymodem_chkcrc();
uint16_t updcrc( uint8_t );
#define xymodem_startpkt() uart0_putc( 'C' );
#define xymodem_sendack() uart0_putc( ACK );
#define xymodem_sendnak() uart0_putc( NAK );
uint8_t S_xymodem_state;
uint8_t S_xymodem_EOTstate;
uint8_t F_firstack;

uint8_t xymodem_main()
{
    uint8_t result = false, result2 = false, retryCount = 0;

#if USE_LCD
    LCD_initIO();
    LCD_Clear();
#endif
    xymodem_init();
    while( 1 )
    {
        result = xymodem_receive( SECOND * 2 );   // wait initpkt
        if( result == ACK )
#ifdef NOWDEBUG
        {
            result2 = xymodem_chkcrc();
            {
                uint8_t buf[ 10 ];
                xsprintf( buf, "%04X=%02X:%02X", CRC, CRCH, CRCL );
                LCD_Puts( buf, 16 );
                LCD_SetCursorPos(0, 1);
            }
        }
        else
        {
#if USE_LCD
            LCD_SetCursorPos(0, 1);
            LCD_Puts("R/NAK",16);
#endif
        }
        if( result2 == true )
#endif
        {
#if USE_LCD
            LCD_SetCursorPos(0, 1);
            LCD_Puts("R/ACK",16);
#endif
            Serial--;
            if( S_xymodem_state != 3 )  // not EOT
            {
                S_xymodem_state = 2;
            }
            else if( S_xymodem_EOTstate == 2 )
            {
                // transfer completed
                return 0;
            }
        }
        else
        {
#if USE_LCD
            LCD_SetCursorPos(0, 1);
            LCD_Puts("R/NAK",16);
#endif
            if( F_firstack == false )
            {
                // Restart
                xymodem_init();
                if( ++retryCount >= 20 )
                {
                    return 1;
                }                
            }
            else
            {
                // Retry
                S_xymodem_state = 1;
            }
        }
    }
}

void xymodem_init()
{
    CRC = 0;
    Serial = 0x0FF;
    S_xymodem_state = 0; F_firstack = false;
    S_xymodem_EOTstate = 0;
}

int16_t get_SIO0_polling( void )
{
#if defined evLPC2388 || defined evADuC7129
    uint8_t stat;
    _NOP(); stat = U0LSR;
    if( ( stat & 0x1 ) != 0 )
    {
        _NOP(); return U0RBR;
    }
    else
    {
        return -1;
    }
#else   // Z80proto
        return getchar_SIO0();
#endif
}

uint8_t xymodem_receive( uint16_t wait )
// timeout: wait <= prevTick - SlowTick(in vic_lpc23xx.c)
{
    uint16_t count = 0, limit, prevTick;
    uint8_t buf, stat;

    // start, receive first byte
    switch( S_xymodem_state )
    {
        case 0:
            // 'C'
            xymodem_startpkt();
            S_xymodem_state = 2;
            break;
        case 1:
            // NAK
            xymodem_sendnak();
            // next S1 or S2
            S_xymodem_state = 2;
            break;
        case 2:
            // ACK or ACK -> 'C'
            xymodem_sendack();
            if( F_firstack == false )
            {   // ACK -> 'C', next S1 or S2
                F_firstack = true;
            }
            break;
        case 3:
            // EOT procedure, (EOT -> NAK) -> EOT -> ACK -> 'C' -> ACK(END)
            // do nothing
        default:
            break;
    }
//    SlowTick = 0;
    prevTick = SlowTick;
#if defined evLPC2388 || defined evADuC7129
    while( 1 )
    {
        _NOP(); stat = U0LSR;
        if( ( stat & 0x01 ) != 0 ) break;
        if( SlowTick > prevTick + wait )
        {
            return NAK;
        }
    }
    _NOP(); buf = U0RBR;
#endif

    switch( buf )
    {
        case SOH:
            limit = 128;
            break;
        case STX:
            limit = 1024;
            break;
        case EOT:
            switch( S_xymodem_EOTstate )
            {
                case 0:
                    xymodem_sendnak();
                    S_xymodem_state = 3;
                    S_xymodem_EOTstate = 1;
                    return NAK;
                case 1:
                    xymodem_sendack();
                    xymodem_startpkt();
                    S_xymodem_state = 3;
                    S_xymodem_EOTstate = 2;
                    return ACK;
                default:
                    // last ACK
                    xymodem_sendack();
                    return ACK;
            }
            break;
        default:
            return NAK;
    }
    limit += 5;
#if USE_LCD
    {
        uint8_t cbuf[ 10 ];
        LCD_SetCursorPos(0, 0);
        xsprintf( cbuf, "%02X->%4d", buf, limit );
        LCD_Puts( cbuf, 12 );
        LCD_SetCursorPos(8, 0);
    }
#endif
    RxBuf[ count++ ] = buf;

    // now, receive second byte ...
    while( 1 )
    {
        buf = get_SIO0_polling();
        if( buf >= 0 )
        {
            RxBuf[ count ] = buf;
//            if( count >= 3 && count <= limit - 2 )
//            {
//                updcrc( buf );
//            }
            count++;
            // timeout rewind
//            SlowTick = 0;
            prevTick = SlowTick;
        }
        if( count >= limit ) // receive succeed(maybe)
        {
#if USE_LCD
            {
                uint8_t cbuf[ 10 ];
                xsprintf( cbuf, "->%4d", count );
                LCD_Puts( cbuf, 6 );
            }
#endif
            CRCL = RxBuf[ --count ];
            CRCH = RxBuf[ --count ];
            return ACK;
        }
        if( SlowTick > prevTick + wait )
        {
#if USE_LCD
            {
                uint8_t cbuf[ 10 ];
                xsprintf( cbuf, "-X%4d", count );
                LCD_Puts( cbuf, 6 );
            }
#endif
            return NAK;
        }
    }
}

uint8_t xymodem_chkcrc()
{
    if( CRC == ( CRCH << 8 ) + CRCL )
    {
        return true;
    }
    return false;
}

uint16_t updcrc( c )
uint8_t c;
{
    uint16_t count;

    for( count = 8 ; --count >= 0; )
    {
        CRC <<= 1;
        CRC += ( ( ( c <<= 1 ) & 0400 ) != 0 );
        if( CRC & 0x8000 )
        {
            CRC ^= 0x1021;
        }
    }
    return CRC;
}
