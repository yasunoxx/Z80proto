// testmode.c

#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#if USE_LCD
    #include "lcd1602.h"
#endif

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

typedef struct {
    uint16_t DestAddr;
    uint8_t SEQ, CRCH, CRCL;
    uint16_t CRC;
    uint8_t S_xymodem_state;
    uint8_t S_xymodem_EOTstate;
    uint8_t F_firstack;
    uint16_t DataCount;
    uint8_t FrameType; // first receive char
} _XYMODEM_WORK_t;
extern  void puts_SIO0( uint8_t * );    // z80sio_sub.asm
extern volatile uint16_t SysTick;
extern volatile uint16_t SlowTick;
extern volatile uint8_t BUF_SIO256[ 256 ];
extern volatile _XYMODEM_WORK_t XYW;

void testmode_init( void );
void testmode_main( void );
void tm_DebugDump( void );
void tm_GetStat_RXF( void );
void tm_GetStat_TXE( void );
uint16_t tm_Flush_FIFO( void );
uint16_t tm_ReadIn_FIFO( void );
uint16_t tm_Write_FIFO( uint8_t *, uint16_t );
bool xymodem_chkcrc( uint16_t );

extern void tm_ZeroFill_buf( void );
extern void tm_Transfer_Dest( void );
volatile bool F_RXF;
volatile bool F_TXE;
/*
volatile union ScratchPad
{
    uint8_t B[ 2 ];
    uint16_t W;
};
*/
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
    tm_DebugDump();
    count = tm_Flush_FIFO();

    XYW.CRC = 0;
    XYW.SEQ = 0x0FF;
    XYW.FrameType = NUL;
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

/*
    sprintf( ( char * )CBuf, "BUF_SIO256:\r\n" );
    puts_SIO0( CBuf );
    for( loop = 0; loop < 256; loop++ )
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
*/
    bool crcstat = xymodem_chkcrc( &BUF_SIO256 );
//    if( crcstat == true )
    {
        sprintf( ( char * )CBuf, "CRC16:0x%04X\r\n", XYW.CRC );
        puts_SIO0( CBuf );
    }
    sprintf( ( char * )CBuf, "\r\n" );
    puts_SIO0( CBuf );
}

void testmode_main()
{
    uint16_t count, prevTick;
    uint8_t TxBuf[ 12 ], TxSEQ = 0, TxSUM;
    uint16_t loop, loop2;

    testmode_init();
    sprintf( ( char * )CBuf, "testmode, Read XMODEM/Sum over FIFO.\r\n" );
    puts_SIO0( CBuf );

    while( 1 )
    {
#ifdef NOWDEBUG
        prevTick = SysTick;
        while( 1 )
        {
            TxBuf[ 0 ] = 'C'; TxBuf[ 1 ] = NUL;
            count = tm_Write_FIFO( TxBuf, 1 );
#if USE_LCD
            LCD_SetCursorPos( 0, 1 );
            sprintf( ( char * )CBuf,
              "Writeout %03d", count );
            LCD_Puts( CBuf, 16 );
#endif
            while( 1 )
            {
                if( SysTick > prevTick + 2000 )
                {
                    prevTick = SysTick;
                    break;
                }
                tm_GetStat_RXF();
                if( F_RXF == false ) goto ReadIn;
            }
        }
#endif

ReadIn:
        BUF_SIO256[ 0 ] = NUL;
        XYW.FrameType = NUL;
        count = tm_ReadIn_FIFO();
        sprintf( ( char * )CBuf, "%02X:ReadIn %04d, ", XYW.SEQ, count );
        puts_SIO0( CBuf );
#if USE_LCD
        LCD_SetCursorPos( 0, 0 );
        sprintf( ( char * )CBuf,
              "%02X:ReadIn %04d", XYW.SEQ, count );
        LCD_Puts( CBuf, 16 );
#endif
        tm_DebugDump();
        if( XYW.FrameType == SOH )
        {
            if( count >= 132 && count <= 133 )
            {
                tm_Transfer_Dest();
                // Send ACK
                TxBuf[ 0 ] = ACK; TxBuf[ 1 ] = NUL;
                sprintf( ( char * )CBuf, "Write SOH/ACK\r\n" );
            }
            else
            {
                // Send ACK
                TxBuf[ 0 ] = NAK; TxBuf[ 1 ] = NUL;
                sprintf( ( char * )CBuf, "Write SOH/NAK\r\n" );
            }
            count = tm_Write_FIFO( TxBuf, 1 );
            puts_SIO0( CBuf );
        }
        else if( XYW.FrameType == EOT )
        {
            // Send ACK
            TxBuf[ 0 ] = ACK; TxBuf[ 1 ] = NUL;
            count = tm_Write_FIFO( TxBuf, 1 );
            sprintf( ( char * )CBuf, "Write EOT/ACK\r\n" );
            puts_SIO0( CBuf );
            sprintf( ( char * )CBuf, "Completed.\r\n" );
            puts_SIO0( CBuf );

            return; // Exit

        }
        else if( XYW.FrameType == STX )
        {
            prevTick = SysTick;
            while( 1 )
            {
                count = tm_Flush_FIFO();
                if( SysTick > prevTick + 500 ) break;
            }

            // Send NAK
            TxBuf[ 0 ] = NAK; TxBuf[ 1 ] = NUL;
            count = tm_Write_FIFO( TxBuf, 1 );
            sprintf( ( char * )CBuf, "Write STX/NAK\r\n" );
            puts_SIO0( CBuf );
        }
        else
        {
            prevTick = SysTick;
            while( 1 )
            {
                count = tm_Flush_FIFO();
                if( SysTick > prevTick + 500 ) break;
            }

            // Send NAK
            TxBuf[ 0 ] = NAK; TxBuf[ 1 ] = NUL;
            count = tm_Write_FIFO( TxBuf, 1 );
            sprintf( ( char * )CBuf, "Write %03X/NAK\r\n", XYW.FrameType );
            puts_SIO0( CBuf );
        }
        tm_Wait( 500 );
    }
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
        if( F_RXF == false )
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
        if( F_RXF == false )
        {
            tm_Wait( 10 );
            tm_SEQ_RD();
            if( count == 0 )
            {
                XYW.FrameType = ScratchPad[ 0 ];
            }
            if( count == 1 )
            {
                XYW.SEQ = ScratchPad[ 0 ];
            }
            if( count < 256 )
            {
                BUF_SIO256[ ( count & 256 ) ] = ScratchPad[ 0 ];
                count++;
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
        ld  a, 0FFh
        ; Read Sequence
        res 0, a    ; PC_RD
        res 2, a    ; PC_CS
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
        ld  a, 0FFh
        ; Write Sequence
        res 1, a    ; PC_WR
        res 2, a    ; PC_CS
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

bool xymodem_chkcrc( uint16_t DestAddr )
{
    // DestAddr = XYW.DestAddr - 128
    ScratchPad[ 0 ] = ( DestAddr & 0x00FF );
    ScratchPad[ 1 ] = ( DestAddr >> 8 );
#asm
chkcrc:
    ld  hl, ( _ScratchPad )
    ld  (DMPAD), hl
    ;
    ; Special Thanks to DemiGod Ippei
    ; CRC16 (C)1987 by Ippei Iwai
    ;
    ;   G(X) = X^16 + X^12 + X^5 + 1
    ;
    LD      A, 16
    ADD     A, A
    ADD     A, A
    ADD     A, A
    LD      B, A        ; B = 128
    LD      HL, (DMPAD)
    JR      CRC1
DMPAD:
    DEFW    0           ; Destination Address
CRC1:
    PUSH    DE          ; first 16 bits
    LD      E, 80H      ; mask pattern
    EXX
    POP     HL          ; first 16 bits
    EXX
    ;
CRC2:
    LD      A, (HL)     ; load 1 byte
    AND     E           ; get bit
    JR      Z, CRC3     ; CY = 0
    SCF                 ; CY = 1
    ;
CRC3:
    EXX
    ADC     HL, HL      ; add the bit to HL
    JR      NC, CRC4    ; non 16th bit
    ;
    LD      A, 10H
    XOR     H
    LD      H, A
    LD      A, 21H      ; 1021H = X^12+X^5+1
    XOR     L
    LD      L, A        ; HL = HL XOR 1021H
    ;
CRC4:
    EXX
    RRC     E           ; rotate mask pattern
    ;                   ; to get next bit
    JR      NC, CRC2    ; case of loop =< 8
    INC     HL          ; next byte
    DJNZ    CRC2
    EXX
    EX      DE, HL
;
CRC5:
    EX      DE, HL
    ;   HL = CRC16


    ld  ( _XYW + 5 ), hl
#endasm
    if( XYW.CRC == ( XYW.CRCH << 8 ) + XYW.CRCL )
    {
        return true;
    }
    return false;
}
