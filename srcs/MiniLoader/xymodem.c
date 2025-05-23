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

void xymodem_init( void );
uint8_t xymodem_receive( uint16_t );   // act receiving w/timeout
uint8_t xymodem_chkcrc();
uint16_t updcrc( uint8_t );
#define xymodem_startpkt() uart0_putc( 'C' );
#define xymodem_sendack() uart0_putc( ACK );
#define xymodem_sendnak() uart0_putc( NAK );
typedef struct {
uint8_t Serial, CRCH, CRCL;
uint16_t CRC;
uint8_t S_xymodem_state;
uint8_t S_xymodem_EOTstate;
uint8_t F_firstack;
} _XYMODEM_WORK_t;

#if defined evLPC2388 || defined evADuC7129
    #include "lpc2300.h"
    #include "uart.h"
    uint8_t RxBuf[ 1034 ];
    uint8_t cbuf[ 32 ];
    extern volatile uint16_t vic_SlowTick;
    volatile _XYMODEM_WORK_t XYW;
    #define SlowTick vic_SlowTick
    #define _NOP() LCD_NOP()
    #define puts_SIO0 uart0_puts
#else   // Z80proto
    void _NOP()
    {
    #asm
        nop
    #endasm
    }
    extern volatile uint16_t SlowTick;
    extern volatile _XYMODEM_WORK_t XYW;
    extern volatile uint8_t BUF_SIO128_0[ 128 ];
    extern volatile uint8_t BUF_SIO128_1[ 128 ];
    #define RxBuf BUF_SIO128_0
    #define cbuf BUF_SIO128_1
    extern  int16_t getchar_SIO0( void );
    extern  void putchar_SIO0( uint8_t );
    extern  void puts_SIO0( uint8_t * );
    #define uart0_getc()    getchar_SIO0()
    #define uart0_putc(x)   putchar_SIO0(x)
#endif

#if USE_LCD
    #if defined evLPC2388 || defined evADuC7129
        #include "xprintf.h"
    #else
        #include <stdio.h>
        #define xsprintf sprintf
    #endif
    #include "lcd1602.h"
#endif


uint8_t xymodem_main()
{
    register uint8_t result = false, result2 = false, retryCount = 0;

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
        if( result == ACK )
#ifdef NOWDEBUG
        {
            result2 = xymodem_chkcrc();
            {
                xsprintf( cbuf, "%04X=%02X:%02X", CRC, CRCH, CRCL );
                LCD_Puts( cbuf, 10 );
                LCD_SetCursorPos( 0, 1 );
            }
        }
        else
        {
    #if USE_LCD
            LCD_SetCursorPos( 0, 1 );
            LCD_Puts( ( uint8_t * )"R/NAK", 16 );
    #endif
        }
        if( result2 == true )
#endif
        {
#if USE_LCD
            LCD_SetCursorPos( 0, 1 );
            LCD_Puts( ( uint8_t * )"R/ACK", 16 );
#endif
            XYW.Serial--;
            if( XYW.S_xymodem_state != 3 )  // not EOT
            {
                XYW.S_xymodem_state = 2;
            }
            else if( XYW.S_xymodem_EOTstate == 2 )
            {
                // transfer completed
                return 0;
            }
        }
        else
        {
#if USE_LCD
            LCD_SetCursorPos( 0, 1 );
            LCD_Puts( ( uint8_t * )"R/NAK", 16 );
#endif
            if( XYW.F_firstack == false )
            {
                // Restart
//                xymodem_init();
//                if( ++retryCount >= 20 )
//                {
//                    _s_tiny_free_( &TN_STRUCT_MEM, RxBuf );
//                    _s_tiny_free_( &TN_STRUCT_MEM, cbuf );
//                    return 1;
//                }
                ;
            }
            else
            {
                // Retry
                XYW.S_xymodem_state = 1;
            }
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
    register uint16_t count = 0, limit, prevTick;
    register uint8_t buf, stat, preCount = 0;

    // start, receive first byte
    switch( XYW.S_xymodem_state )
    {
        case 0:
            // 'C'
            xymodem_startpkt();
            XYW.S_xymodem_state = 2;
            break;
        case 1:
            // NAK
            xymodem_sendnak();
            // next S1 or S2
            XYW.S_xymodem_state = 2;
            break;
        case 2:
            // ACK or ACK -> 'C'
            xymodem_sendack();
            if( XYW.F_firstack == false )
            {   // ACK -> 'C', next S1 or S2
                XYW.F_firstack = true;
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
    while( 1 )
    {
#if defined evLPC2388 || defined evADuC7129
        _NOP(); stat = U0LSR;
        if( ( stat & 0x01 ) != 0 )
        {
            _NOP(); buf = U0RBR;
            break;
        }
#else   // Z80proto
        buf = getchar_SIO0();
        if( buf >= 0 )
        {
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
//            limit = 1024;
//            break;
            return NAK;
        case EOT:
            switch( XYW.S_xymodem_EOTstate )
            {
                case 0:
                    xymodem_sendnak();
                    XYW.S_xymodem_state = 3;
                    XYW.S_xymodem_EOTstate = 1;
                    return NAK;
                case 1:
                    xymodem_sendack();
                    xymodem_startpkt();
                    XYW.S_xymodem_state = 3;
                    XYW.S_xymodem_EOTstate = 2;
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
#if USE_LCD
    {
        LCD_SetCursorPos( 0, 0 );
        xsprintf( ( char * )cbuf, ( const char * )"%02X->%4d", buf, limit );
        LCD_Puts( cbuf, 12 );
        LCD_SetCursorPos( 8, 0 );
    }
#endif
    limit += 5;
    RxBuf[ count ] = buf;   // for debug
    _NOP();
    preCount = 1;

    // now, receive second byte ...
    while( 1 )
    {
        buf = get_SIO0_polling();
        if( buf >= 0 )
        {
            switch( count )
            {
                case 128:
                    XYW.CRCH = buf;
                    break;
                case 129:
                    XYW.CRCL = buf; // receive succeed(maybe)
//                updcrc( buf );
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
                    RxBuf[ count ] = buf;
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
            return NAK;
        }
    }
}

uint8_t xymodem_chkcrc()
{
    if( XYW.CRC == ( XYW.CRCH << 8 ) + XYW.CRCL )
    {
        return true;
    }
    return false;
}

uint16_t updcrc( c )
uint8_t c;
{
    register uint16_t count;

    for( count = 8 ; --count >= 0; )
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
