/*
 * lcd.h -- SPI and 40x4 Char. LCD for MSP430G2553
 * (C)2025 by yasunoxx▼Julia
 * ### Use TI-MSPGCC6.1.1.0 or above version ###
 */

/* lcd.c */
extern void InitLCD( void );
extern void SubLCD( void );

extern unsigned char BufLCD[ 4 ][ 40 ];

#define MSB   0
#define LSB   1

#define LCD_RS    BIT3
#define LCD_E1    BIT6
#define LCD_E2    BIT7
#define LCD_CMD   0
#define LCD_DATA  1
#define	LCDC_DIR   P1DIR
#define	LCDC_OUT   P1OUT
#define	LCDD_DIR   P2DIR
#define	LCDD_OUT   P2OUT

#define ROW_H   0
#define ROW_L   1
