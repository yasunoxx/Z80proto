// testmode.c

#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include "parse.h"
#include "control.h"

#if USE_LCD
    #include "lcd1602.h"
#endif

#ifndef HIGH
    #define HIGH true
    #define LOW false
#endif

typedef struct
{
    uint16_t SEQ;
    uint16_t DestAddr;
    uint8_t Result;
    uint8_t CRC8;
    bool F_Trace;
    uint8_t RealSize;
} _TM_WORK_t;

extern void puts_SIO0( uint8_t * );    // z80sio_sub.asm
extern volatile uint16_t SysTick;
extern volatile uint16_t SlowTick;
extern volatile uint8_t BUF_SIO256[ 256 ];
extern volatile _TM_WORK_t TM;

void testmode_init( void );
void testmode_main( void );
int16_t tm_Parse( void );
bool tm_Parse2( uint8_t );
void tm_DebugDump( void );
void tm_GetStat_RXF( void );
void tm_GetStat_TXE( void );
uint16_t tm_Flush_FIFO( void );
uint16_t tm_ReadIn_FIFO( void );
uint16_t tm_Write_FIFO( uint8_t *, uint16_t );
bool tm_chkcrc( uint8_t *buf );
bool xymodem_chkcrc( uint16_t );

extern void tm_ZeroFill_buf( void );
extern void tm_Transfer_Dest( void );
volatile bool F_RXF;
volatile bool F_TXE;
volatile uint8_t ScratchPad[ 2 ];
volatile uint8_t CBuf[ 64 ];

void testmode_init()
{
    uint16_t count;
#if USE_LCD
    LCD_Init();
    LCD_Clear();
#endif
    tm_ZeroFill_buf();
//    tm_DebugDump();
    count = tm_Flush_FIFO();

    TM.CRC8 = 0;
    TM.SEQ = 0x0FFFF;
    TM.F_Trace = false;
}

void tm_Wait( uint16_t wait )
{
    uint16_t prevTick = SysTick;
    while( 1 )
    {
        if( SysTick > prevTick + wait ) break;
    }
}

void tm_DebugDump()
{
    uint16_t loop, loop2;

    sprintf( ( char * )CBuf, "BUF_SIO256:\r\n" );
    puts_SIO0( CBuf );
//    for( loop = 0; loop < 256; loop++ )
    for( loop = 0; loop < 128; loop++ )
    {
        for( loop2 = 0; loop2 < 16; loop2++ )
        {
            sprintf( ( char * )CBuf, "%02X", BUF_SIO256[ loop++ ] );
            puts_SIO0( CBuf );
            if( loop2 == 3 || loop2 == 7 || loop2 == 11 )
            {
                CBuf[ 0 ] = ' '; CBuf[ 1 ] = NUL;
                puts_SIO0( CBuf );
            }
        }
        loop--;
        sprintf( ( char * )CBuf, "\r\n" );
        puts_SIO0( CBuf );
    }

    bool crcstat = tm_chkcrc( BUF_SIO256 );
//    if( crcstat == true )
    {
        sprintf( ( char * )CBuf, "CRC8:0x%02X\r\n", TM.CRC8 );
        puts_SIO0( CBuf );
    }
    sprintf( ( char * )CBuf, "\r\n" );
    puts_SIO0( CBuf );
}

// #define DEBUG 1
void testmode_main()
{
    uint16_t count, prevTick;
    uint8_t TxBuf[ 12 ], TxSEQ = 0, TxSUM;
    uint16_t loop, loop2;

    testmode_init();
    sprintf( ( char * )CBuf, "testmode, Read over FIFO.\r\n" );
    puts_SIO0( CBuf );

    while( 1 )
    {
        // wait FIFO RxFill
        while( 1 )
        {
            prevTick = SysTick;
            while( 1 )
            {
                if( SysTick > prevTick + 10 )
                {
                    prevTick = SysTick;
                    break;
                }
            }
            tm_GetStat_RXF();
            if( F_RXF == LOW ) break; // goto ReadIn;
        }

ReadIn:
        {
            uint8_t countz = 0;
            BUF_SIO256[ 0 ] = NUL;
            while( 1 )
            {
                count = tm_ReadIn_FIFO();
                countz += count;
                if( countz >= FIFO_PACKET_SIZE ) break;
            }
#ifdef DEBUG
            sprintf( ( char * )CBuf, "ReadIn %04d, ", count );
            puts_SIO0( CBuf );
#endif
#if USE_LCD
            LCD_SetCursorPos( 0, 0 );
            sprintf( ( char * )CBuf,
                  "%04X:ReadIn %04d", TM.SEQ, count );
            LCD_Puts( CBuf, 16 );
#endif
        }
        // Parse BUF_SIO256
        TM.CRC8 = 0;
        int16_t cmd = tm_Parse();
        bool result;
        if( cmd >= 0 )
        {
            result = tm_Parse2( ( uint8_t )cmd );
        }
        if( result == true )
        {
            TM.CRC8 = 0;
            tm_chkcrc( BUF_SIO256 );
            BUF_SIO256[ IDX_CRCL ] = TM.CRC8;
            BUF_SIO256[ IDX_ETX ] = ETX;
    
            result = tm_Write_FIFO( BUF_SIO256, FIFO_PACKET_SIZE );
            if( cmd == QUIT )
            {
                return;
            }
        }
        else
        {
            tm_DebugDump();
        }
    }
}

#define DEBUG 1
int16_t tm_Parse()
{
    int16_t loop;
    bool cmp = false;

//  typedef struct
//  {
//      uint16_t SEQ;
//      uint16_t DestAddr;
//      uint8_t Result;
//      uint8_t CRC8;
//      bool F_Trace;
//      uint8_t RealSize;
//  } _TM_WORK_t;
    TM.SEQ = ( BUF_SIO256[ IDX_SEQH ] << 8 ) |
               BUF_SIO256[ IDX_SEQL ];

    // compare BUF_SIO256 and TxFormat
    for( loop = 0; loop <= QUIT; loop++ )
    {
        if( BUF_SIO256[ IDX_CMD0 ] == RxFormat[ loop ][ 2 ] &&
            BUF_SIO256[ IDX_CMD1 ] == RxFormat[ loop ][ 3 ] &&
            BUF_SIO256[ IDX_CMD2 ] == RxFormat[ loop ][ 4 ] )
        {
            TM.RealSize = BUF_SIO256[ IDX_SIZE ]; // WMx, RMx real size
            TM.DestAddr = ( BUF_SIO256[ IDX_ADDRH ] << 8 ) | // Src/Dest address MSB
                          BUF_SIO256[ IDX_ADDRL ];           // Src/Dest address LSB
            bool crcstat = tm_chkcrc( BUF_SIO256 );
            if( crcstat == true )
            {
                TM.Result = ACK;
            }
            else
            {
                TM.Result = NAK;
            }
            cmp = true;
            break;
        }
    }
    if( cmp == false )
    {
        return -1;
    }

#ifdef DEBUG
    sprintf( ( char * )CBuf, "STX #%04X SYN ", TM.SEQ );
    puts_SIO0( CBuf );
    if( BUF_SIO256[ IDX_CMD0 ] == PAD )
    {
        sprintf( ( char * )CBuf, "PAD PAD ... " );
    }
    else if( BUF_SIO256[ IDX_CMD0 ] == 0xA5 )
    {
        sprintf( ( char * )CBuf, "0xA5 PAD ... " );
    }
    else if( BUF_SIO256[ IDX_CMD1 ] == 'M' ||
             BUF_SIO256[ IDX_CMD1 ] == 'P' )
    {
        sprintf( ( char * )CBuf, "STX >%C >%C #%02D #%02D ",
                 BUF_SIO256[ IDX_CMD0 ],
                 BUF_SIO256[ IDX_CMD1 ],
                 BUF_SIO256[ IDX_CMD2 ],
                 BUF_SIO256[ IDX_SIZE ] );
    }
    else
    {
        sprintf( ( char * )CBuf, "STX >%C >%C >%C PAD ",
                 BUF_SIO256[ IDX_CMD0 ],
                 BUF_SIO256[ IDX_CMD1 ],
                 BUF_SIO256[ IDX_CMD2 ] );
    }
    puts_SIO0( CBuf );
#endif
    if( TM.Result == ACK )
    {
        sprintf( ( char * )CBuf, "ACK\r\n" );
    }
    else
    {
        sprintf( ( char * )CBuf, "NAK[%02X]\r\n", TM.CRC8 );
    }
    puts_SIO0( CBuf );

    return loop;
}

void tm_AppendACK( uint8_t stat )
{
    BUF_SIO256[ IDX_ACKNAK ] = stat;
}

//#define DEBUG 1
bool tm_Parse2( uint8_t cmd )
{
    bool result = false;
    tm_AppendACK( NAK );
    switch( cmd )
    {
        case START:
#ifdef DEBUG
            sprintf( ( char * )CBuf,
                     "Receive START\r\n" );
            puts_SIO0( CBuf );
#endif
            result = true;
            break;
    case NOP:
#ifdef DEBUG
            sprintf( ( char * )CBuf,
                     "Receive NOP\r\n" );
            puts_SIO0( CBuf );
#endif
            result = true;
            break;
        case SET_BP:
#ifdef DEBUG
            sprintf( ( char * )CBuf,
                     "Receive SET_BP\r\n" );
            puts_SIO0( CBuf );
#endif
            result = true;
            break;
        case REG:
#ifdef DEBUG
            sprintf( ( char * )CBuf,
                     "Receive REG\r\n" );
            puts_SIO0( CBuf );
#endif
            result = true;
            break;
        case WM64:
#ifdef DEBUG
            sprintf( ( char * )CBuf,
                     "Receive WM64\r\n" );
            puts_SIO0( CBuf );
#endif
            result = true;
            break;
        case WM01:
#ifdef DEBUG
            sprintf( ( char * )CBuf,
                     "Receive WM01\r\n" );
            puts_SIO0( CBuf );
#endif
            result = true;
            break;
        case RM64:
#ifdef DEBUG
            sprintf( ( char * )CBuf,
                     "Receive RM64\r\n" );
            puts_SIO0( CBuf );
#endif
            result = true;
            break;
        case RM01:
#ifdef DEBUG
            sprintf( ( char * )CBuf,
                    "Receive RM01\r\n" );
            puts_SIO0( CBuf );
#endif
            result = true;
            break;
        case QUIT:
#ifdef DEBUG
           sprintf( ( char * )CBuf,
                     "Receive QUIT\r\n" );
            puts_SIO0( CBuf );
#endif
            result = true;
        default:
            break;
    }

    if( result == true )
    {
        tm_AppendACK( ACK );
    }
    return result;
}

void tm_SEQ_RD( void );
void tm_SEQ_WR( void );
void tm_SetRead( void );
void tm_SetWrite( void );

void tm_GetStat_RXF()
{
#asm
    PPI0PA   EQU 30h
    PPI0PC   EQU 32h
    PC_RXF  EQU 6
    
    in  a, ( PPI0PC )
    bit PC_RXF, a
    jr  nz, _tm_asm_01
    xor a       ; RXF# 'L' -> Flag LOW
    jr  _tm_asm_02
_tm_asm_01:
    ld  a, 1    ; Flag HIGH
_tm_asm_02:
    ld  (_F_RXF), a
#endasm
}

void tm_GetStat_TXE()
{
#asm
    PC_TXE  EQU 7
    
    in  a, ( PPI0PC )
    bit PC_TXE, a
    jr  nz, _tm_asm_03
    xor a       ; TXE# 'L' -> Flag LOW
    jr  _tm_asm_04
_tm_asm_03:
    ld  a, 1    ; Flag HIGH
_tm_asm_04:
    ld  (_F_TXE), a
#endasm
}

uint16_t tm_Flush_FIFO()
{
    uint16_t count = 0;

    while( 1 )
    {
        tm_GetStat_RXF();
        if( F_RXF == LOW )
        {
            tm_Wait( 10 );
            tm_SEQ_RD();
            count++;
        }
        else
        {
            break;
        }
    }

    return count;
}

uint16_t tm_ReadIn_FIFO()
{
    uint16_t count = 0;

    while( 1 )
    {
        tm_GetStat_RXF();
        if( F_RXF == LOW )
        {
            tm_Wait( 10 );
            tm_SEQ_RD();
            {
                BUF_SIO256[ count++ ] = ScratchPad[ 0 ];
            }
        }
        else
        {
            break;
        }
    }

    return count;
}

uint16_t tm_Write_FIFO( uint8_t *buf, uint16_t size )
{
    int16_t count = 0;

    while( 1 )
    {
        tm_GetStat_TXE();
        if( F_TXE == false )
        {
            ScratchPad[ 0 ] = buf[ count++ ];
            tm_SEQ_WR();
            if( count >= size ) break;
        }
        else
        {
            break;
        }
    }

    return ( uint16_t )count;
}

void tm_SEQ_RD( void )
{
    {
        // Set Read
        tm_SetRead();
    }

    {
#asm
        ; Read Sequence
        ; ld  a, 0FFh
        ; res 0, a    ; PC_RD
        ; res 2, a    ; PC_CS
        ld  a, ( 0FFh | 00001010b )
        out ( PPI0PC ), a
        ; FIFO Read
        in  a, ( PPI0PA )
        ld  ( _ScratchPad ), a
        ; Read End
        ld  a, 0FFh
        out ( PPI0PC ), a
#endasm
    }
}

void tm_SEQ_WR( void )
{
    {
        // Set Write
        tm_SetWrite();
    }

    {
#asm
        ; Write Sequence
        ; ld  a, 0FFh
        ; res 1, a    ; PC_WR
        ; res 2, a    ; PC_CS
        ld  a, ( 0FFh | 00001001b )
        out ( PPI0PC ), a
        ; FIFO Write
        ld  a, ( _ScratchPad )
        out ( PPI0PA ), a
        ; Write End
        ld  a, 0FFh
        out ( PPI0PC ), a
#endasm
    }

    {
        // Set Read(For Safety)
        tm_SetRead();
    }
}

extern uint8_t calcCRC8CCITT( uint8_t crc, uint8_t buf );

bool tm_chkcrc( uint8_t *buf )
{
    uint8_t loop;

    for( loop = 0; loop <= FIFO_TRAILER_SIZE; loop++ )
    {
        TM.CRC8 = calcCRC8CCITT( TM.CRC8, buf[ loop + 3 ] );
    }
    if( TM.CRC8 == buf[ loop + 5 ] )
    {
        return true;
    }
    return false;
}
