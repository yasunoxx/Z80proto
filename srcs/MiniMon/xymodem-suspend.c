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

#define SEQSTART  0
#define SEQNAK  1
#define SEQACK  2
#define SEQEOT  3
#define SEQRESTART  4

#define SECOND 2    // SlowTick increment 500msec/count

#include <stdint.h>
#include <stdbool.h>

void xymodem_init( void );
uint8_t xymodem_receive( uint16_t );   // act receiving w/timeout
void SIO0_flush( uint16_t );
bool xymodem_chkcrc();
uint16_t updcrc( uint16_t );
#define xymodem_startpkt() uart0_putc( 'C' );
#define xymodem_sendack() uart0_putc( ACK );
#define xymodem_sendnak() uart0_putc( NAK );
typedef struct {
uint16_t DestAddr;
uint8_t Serial, CRCH, CRCL;
uint16_t CRC;
uint8_t S_xymodem_state;
uint8_t S_xymodem_EOTstate;
uint8_t F_firstack;
uint16_t DataCount;
} _XYMODEM_WORK_t;

#if defined evLPC2388 || defined evADuC7129
    #include "lpc2300.h"
    #include "xprintf.h"
    #include "uart.h"
    uint8_t RxBuf[ 1034 ];
    uint8_t cbuf[ 32 ];
    extern volatile uint16_t vic_SlowTick;
    volatile _XYMODEM_WORK_t XYW;
    #define SlowTick vic_SlowTick
    #define _NOP() LCD_NOP()
    #define puts_SIO0 uart0_puts
#else   // Z80proto
    #include <stdio.h>
    #define xsprintf sprintf
    void _NOP()
    {
    #asm
        nop
    #endasm
    }
    extern volatile uint16_t SysTick;
    extern volatile uint16_t SlowTick;
    extern volatile _XYMODEM_WORK_t XYW;
    extern volatile uint8_t BUF_SIO128_0[ 128 ];
    extern volatile uint8_t BUF_SIO128_1[ 128 ];
    #define RxBuf BUF_SIO128_0
    #define cbuf BUF_SIO128_1
    extern volatile uint16_t BUF_GETCHAR_SIO0;
    extern  void Transfer_Dest_xymodem( void );
    extern  int16_t getchar_SIO0( void );
    extern  int16_t getchar_SIO0_as( int16_t * );
    int16_t SIO0_as_buf;
    extern  void putchar_SIO0( uint8_t );
    extern  void puts_SIO0( uint8_t * );
    #define uart0_getc()    getchar_SIO0()
    #define uart0_putc(x)   putchar_SIO0(x)
#endif

#if USE_LCD
    #include "lcd1602.h"
#endif

// Set XYW.DestAddr before call xymodem_main()
#if defined evLPC2388 || defined evADuC7129
// use convenient function xymodem_SetDestAddr()
void xymodem_SetDestAddr( uint16_t addr )
{
    XYW.DestAddr = addr;
}
#endif

void D_clrCount( void )
{
    XYW.DataCount = 0;
}
void D_incCount( void )
{
    XYW.DataCount++;
}
void D_dispCount( void )
{
#if USE_LCD
    {
        LCD_SetCursorPos( 0, 0 );
        xsprintf( ( char * )cbuf, "%05d", XYW.DataCount );
        LCD_Puts( cbuf, 6 );
    }
#endif
}

uint8_t xymodem_main()
{
    uint8_t result = false, result2 = false, retryCount = 0;

#if USE_LCD
    LCD_Init();
    LCD_Clear();
#endif
    {
        xsprintf( ( char * )cbuf, "xymodem.c, send anything\r\n" );
        puts_SIO0( cbuf );
    }
    xymodem_init();
    while( 1 )
    {
        result = xymodem_receive( SECOND * 2 );   // wait initpkt
        switch( result )
        {
            case ACK:
//                result2 = xymodem_chkcrc();
#if USE_LCD
                {
                    LCD_SetCursorPos( 0, 1 );
                    LCD_Puts( ( uint8_t * )"R/ACK", 16 );
                    LCD_SetCursorPos( 6, 1 );
                    xsprintf( ( char * )cbuf,
                              "%04X=%02X:%02X", XYW.CRC, XYW.CRCH, XYW.CRCL );
                    LCD_Puts( cbuf, 10 );
                }
#endif
                if( XYW.F_firstack == true )
                {
#if defined evLPC2388 || defined evADuC7129
                    // transfer memarea
                    XYW.DestAddr += 128;
#else // Z80proto
                    Transfer_Dest_xymodem();
#endif
#if USE_LCD
                    {
                        LCD_SetCursorPos( 4, 0 );
                        xsprintf( ( char * )cbuf, "0x%08X", XYW.DestAddr );
                        LCD_Puts( cbuf, 10 );
                    }
#endif
                }
                XYW.Serial--;
                XYW.S_xymodem_state = SEQACK;
                break;
            case EOT:
#if USE_LCD
                {
                    LCD_SetCursorPos( 0, 1 );
                    LCD_Puts( ( uint8_t * )"R/EOT", 16 );
                }
#endif
                if( XYW.S_xymodem_EOTstate >= 2 )
                {
                    // transfer completed
                    return 0;
                }
                break;
            case NAK:
            default:
                if( XYW.F_firstack == false )
                {
#if USE_LCD
                    {
                        LCD_SetCursorPos( 0, 1 );
                        LCD_Puts( ( uint8_t * )"RESTA", 16 );
                    }
#endif
                    // Restart
                    xymodem_init();
                    XYW.S_xymodem_state = SEQRESTART;
                  if( ++retryCount >= 20 )
                  {
                        return 1;
                  }
                }
                else
                {
                    // Retry
                    XYW.S_xymodem_state = SEQNAK;
#if USE_LCD
                    {
                        LCD_SetCursorPos( 0, 1 );
                        LCD_Puts( ( uint8_t * )"R/NAK", 16 );
                    }
#endif
                    uint16_t prevTick = SlowTick;
                    while( 1 )
                    {
                        if( SlowTick > prevTick + 1 )   // 500msec
                        {
                            break;
                        }
                    }
                }
                break;
            // end switch()
        }
    }
}

void xymodem_init()
{
    XYW.CRC = 0;
    XYW.Serial = 0x0FF;
    XYW.S_xymodem_state = 0; XYW.F_firstack = false;
    XYW.S_xymodem_EOTstate = 0;
}

#if defined evLPC2388 || defined evADuC7129
int16_t get_SIO0_polling( void )
{
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
}
#else   // Z80proto
#ifndef NOWDEBUG
int16_t get_SIO0_polling( void )
{
    uint16_t prevTick;

    return 0x00AA;

    prevTick = SlowTick;
    while( 1 )
    {
        getchar_SIO0();
        uint16_t tbuf = BUF_GETCHAR_SIO0;
        if( ( tbuf & 0x00FF00 ) == 0 )
        {
            return ( int16_t )tbuf;
        }
        if( SlowTick > prevTick + 1 )   // 500msec
        {
            return -1;
        }
    }
}
#endif
#endif

void SIO0_flush( uint16_t wait )
{
    uint16_t prevTick = SlowTick;
    while( 1 )
    {
#if defined evLPC2388 || defined evADuC7129
        {
            uint8_t stat;
            _NOP(); stat = U0LSR;
            if( ( stat & 0x1 ) != 0 )
            {
                _NOP(); stat = U0RBR;
                break;
            }
        }
#else        
        getchar_SIO0();
#endif
        if( SlowTick > prevTick + wait )
        {
            break;
        }
    }
}

uint8_t xymodem_receive( uint16_t wait )
// timeout: wait <= prevTick - SlowTick(in vic_lpc23xx.c)
{
    uint16_t count = 0, limit, prevTick;
    uint8_t buf, stat, preCount = 0;

    // start, receive first byte
    switch( XYW.S_xymodem_state )
    {
        case SEQSTART:
            // 'C'
            xymodem_startpkt();
            XYW.S_xymodem_state = SEQACK;
            break;
        case SEQRESTART:
            // NAK -> 'C'
//            xymodem_sendnak();
            xymodem_startpkt();
            XYW.S_xymodem_state = SEQACK;
            break;
        case SEQNAK:
            // NAK
            xymodem_sendnak();
            // next S1 or S2
            XYW.S_xymodem_state = SEQACK;
            break;
        case SEQACK:
            // ACK or ACK -> 'C'
            xymodem_sendack();
            if( XYW.F_firstack == false )
            {   // ACK -> 'C', next S1 or S2
                XYW.F_firstack = true;
            }
            XYW.S_xymodem_state = SEQACK;
            break;
        case SEQEOT:
            // EOT procedure, (EOT -> NAK) -> EOT -> ACK -> 'C' -> ACK(END)
            // do nothing
            XYW.S_xymodem_state = SEQEOT;
        default:
            break;
    }

    prevTick = SlowTick;
    while( 1 )
    {
#if defined evLPC2388 || defined evADuC7129
        _NOP(); stat = U0LSR;
        if( ( stat & 0x01 ) != 0 )
        {
            _NOP(); buf = ( int16_t )U0RBR;
            break;
        }
#else   // Z80proto
        getchar_SIO0();
        uint16_t tbuf = BUF_GETCHAR_SIO0;
        if( ( tbuf & 0x00FF00 ) == 0 )
        {
            buf = ( uint8_t )tbuf;
            break;
        }
#endif
        if( SlowTick > prevTick + wait )
        {
            return NAK;
        }
    }

    switch( buf )
    {
        case SOH:
            limit = 128;
            break;
        case STX:
            break;
        case EOT:
            XYW.S_xymodem_state = SEQEOT;
            switch( XYW.S_xymodem_EOTstate )
            {
                case 1:
                    xymodem_sendack();
                    xymodem_startpkt();
                    XYW.S_xymodem_EOTstate = 2;
                    return EOT;
                case 2:
                    // last ACK
                    xymodem_sendack();
                    XYW.S_xymodem_EOTstate = 3;
                    return EOT;
                case 0:
                default:
                    xymodem_sendnak();
                    XYW.S_xymodem_EOTstate = 1;
                    return EOT;
        }
            break;
        default:
            return NAK;
    }
#if USE_LCD
    {
        LCD_SetCursorPos( 0, 0 );
        xsprintf( ( char * )cbuf, ( const char * )"%02X->%4d", buf, limit );
        LCD_Puts( cbuf, 12 );
        LCD_SetCursorPos( 8, 0 );
    }
#endif
    if( buf == STX )
    {
        return NAK;
    }

    limit += 5;
    preCount = 1;

    // FIXME: now, receive second byte ...
    prevTick = SlowTick;
    while( 1 )
    {
        int16_t tbuf = get_SIO0_polling();
        if( tbuf >= 0 )
        {
            switch( count )
            {
                case 128:
                    _NOP();
                    XYW.CRCH = ( uint8_t )tbuf;
                    break;
                case 129:
                    _NOP();
                    XYW.CRCL = ( uint8_t )tbuf; // receive succeed(maybe)
                    {
#if USE_LCD
            {
                xsprintf( ( char * )cbuf, ( const char * )"->%4d", count - 1 );
                LCD_Puts( cbuf, 6 );
            }
#endif
                        return ACK;
                    }
                    break;
                default:
                  RxBuf[ count ] = ( uint8_t )tbuf;
//                    updcrc( ( uint8_t )tbuf );
            }

            preCount++;
            if( preCount > 2 )  // ignore head(3bytes)
            {
                count++;
            }
            prevTick = SlowTick;
        }
        if( SlowTick > prevTick + wait )
        {
#if USE_LCD
            {
                xsprintf( ( char * )cbuf, ( const char * )"-X%4d", count );
                LCD_Puts( cbuf, 6 );
            }
#endif
//            SIO0_flush( 1 );
            return NAK;
        }
    }
}

bool xymodem_chkcrc()
{
    if( XYW.CRC == ( XYW.CRCH << 8 ) + XYW.CRCL )
    {
        return true;
    }
    return false;
}

uint16_t updcrc( c )
uint16_t c;
{
    uint8_t count;

    for( count = 7 ; count >= 0; count-- )
    {
        XYW.CRC <<= 1;
        XYW.CRC += ( ( ( c <<= 1 ) & 0400 ) != 0 );
        if( XYW.CRC & 0x8000 )
        {
            XYW.CRC ^= 0x1021;
        }
    }
    return XYW.CRC;
}
