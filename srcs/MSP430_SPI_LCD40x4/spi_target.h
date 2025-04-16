/*
 * spi_target.h -- SPI and 40x4 Char. LCD for MSP430G2553
 * (C)2021,2022,2025 by yasunoxx▼Julia
 * ### Use TI-MSPGCC6.1.1.0 or above version ###
 */

#define TARGET_CS_IN     P1IN
#define TARGET_CS_DIR    P1DIR
#define TARGET_CS        BIT3

#define NUL 0
#define ACK 0x06
#define NAK 0x15
#define LF  0x0A
#define FF  0x0C
#define CR  0x0D

#define STATE_INIT 1

extern volatile unsigned char F_SPI_Receive; // main.c

#define SIZE_RXBUF  64
extern uint8_t CopyArray( unsigned char *, unsigned char *, uint8_t );
extern unsigned char getchar_SPI( void );
extern void InitSPI( void );
