/*
 * lcd.c -- SPI and 40x4 Char. LCD for MSP430G2553
 * (C)2025 by yasunoxx▼Julia
 * ### Use TI-MSPGCC6.1.1.0 or above version ###
 */

#ifdef GCC_VERSION_463
#include <legacymsp430.h>
#else
#include <msp430g2553.h>
#endif
#include <string.h>
#include <stdio.h>
#include "io.h"
#include "lcd.h"
#include "tlv.h"

#define TRUE  1
#define FALSE 0

struct _b2n
{
  unsigned char data;
  unsigned char nibbles[ 2 ];
} b2n;

unsigned char BufLCD[ 4 ][ 40 ];
const unsigned char mesLCD[ 4 ][ 40 ] = {
// 0123456789012345678901234567890123456789
  "ProtoR02 test                          X",
  "                                       Y",
  "                                       Z",
  "                                    XYZZ"
};
const unsigned char regLCD[ 4 ][ 40 ] = {
// 0123456789012345678901234567890123456789
  "Break                                   ",
  "Reg. AF:XXXX, BC:XXXX, DE:XXXX, HL:XXXX ",
  "     IX:XXXX, IY:XXXX, SP:XXXX, PC:XXXX ",
  "                                        "
};

extern const char *FW_Version;	// in main.c
extern volatile unsigned short LcdWait;
extern unsigned short ScreenWait;

volatile unsigned char subState_LCD;
int tempSMA[ 32 ];
unsigned char tempSMApos, tempSMAcount;


#define F_SHORT 0
#define F_LONG  1
void lcd_wait( char flag_long );
void InitLCD( void );
void SubLCD( void );
void lcd_cmd8( unsigned char command, unsigned char hl );
void lcd_data8( unsigned char data, unsigned char hl );
void byte2nibbles( void );


void InitLCD( void )
{
  unsigned char loop;

  LCDC_DIR |= LCD_RS + LCD_E1 + LCD_E2;
  LCDD_DIR |= 0x0FF;

  for( loop = 0; loop <= 39; loop++ )
  {
    BufLCD[ 0 ][ loop ] = mesLCD[ 0 ][ loop ];
    BufLCD[ 1 ][ loop ] = mesLCD[ 1 ][ loop ];
    BufLCD[ 2 ][ loop ] = mesLCD[ 2 ][ loop ];
    BufLCD[ 3 ][ loop ] = mesLCD[ 3 ][ loop ];
  }
  BufLCD[ 1 ][ 4 ] = FW_Version[ 0 ];
  BufLCD[ 1 ][ 5 ] = FW_Version[ 1 ];
  BufLCD[ 1 ][ 6 ] = FW_Version[ 2 ];
  BufLCD[ 1 ][ 7 ] = FW_Version[ 3 ];

  subState_LCD = 0;

  for( loop = 0; loop <= 31; loop++ )
  {
    tempSMA[ loop ] = 0;
  }
  tempSMApos = 0;
  tempSMAcount = 0;
}

void SubLCD( void )
{
  unsigned char loop;

  switch( subState_LCD )
  {
    case 0:
      // init state 1
      lcd_cmd8( 0x30, ROW_H );   // set 8bit mode
      lcd_cmd8( 0x30, ROW_L );
      lcd_wait( F_LONG );
      subState_LCD = 1;
      break;
    case 1:
      // init state 2
      lcd_cmd8( 0x30, ROW_H );   // repeat
      lcd_cmd8( 0x30, ROW_L );
      lcd_wait( F_LONG );
      subState_LCD = 2;
      break;
    case 2:
      // init state 3
      lcd_cmd8( 0x30, ROW_H );
      lcd_cmd8( 0x30, ROW_L );
      lcd_wait( F_LONG );
      subState_LCD = 3;
      break;
    case 3:
      // init state 4
      lcd_cmd8( 0x38, ROW_H );   // set 8bit mode, 2 rows, 5*7 dots
      lcd_cmd8( 0x08, ROW_H );   // hidden display
      lcd_cmd8( 0x0C, ROW_H );   // display, no cursor
      lcd_cmd8( 0x06, ROW_H );   // write increment
      lcd_cmd8( 0x02, ROW_H );   // cursor home
      //
      subState_LCD = 4;
      break;
    case 4:
      // init state 5
      lcd_cmd8( 0x38, ROW_L );   // set 8bit mode, 2 rows, 5*7 dots
      lcd_cmd8( 0x08, ROW_L );   // hidden display
      lcd_cmd8( 0x0C, ROW_L );   // display, no cursor
      lcd_cmd8( 0x06, ROW_L );   // write increment
      subState_LCD = 5;
      break;
    case 5:
      // regular state 1
      lcd_cmd8( 0x80, ROW_H );   // cursor first row home
      for( loop = 0; loop <= 19; loop++ )
        lcd_data8( BufLCD[ 0 ][ loop ], ROW_H );
      subState_LCD = 6;
      break;
    case 6:
      // regular state 2
      for( loop = 20; loop <= 39; loop++ )
        lcd_data8( BufLCD[ 0 ][ loop ], ROW_H );
//      lcd_wait( F_SHORT );
      subState_LCD = 7;
      break;
    case 7:
      // regular state 3
      lcd_cmd8( 0x0C0, ROW_H );   // cursor second row home
      for( loop = 0; loop <= 19; loop++ ) 
        lcd_data8( BufLCD[ 1 ][ loop ], ROW_H );
      subState_LCD = 8;
      break;
    case 8:
      // regular state 4
      for( loop = 20; loop <= 39; loop++ ) 
        lcd_data8( BufLCD[ 1 ][ loop ], ROW_H );
//      lcd_wait( F_SHORT );
      subState_LCD = 9;
      break;
    case 9:
      // regular state 5
      lcd_cmd8( 0x80, ROW_L );   // cursor first row home
      for( loop = 0; loop <= 19; loop++ )
        lcd_data8( BufLCD[ 2 ][ loop ], ROW_L );
      subState_LCD = 10;
      break;
    case 10:
      // regular state 6
      for( loop = 20; loop <= 39; loop++ )
        lcd_data8( BufLCD[ 2 ][ loop ], ROW_L );
//      lcd_wait( F_SHORT );
      subState_LCD = 11;
      break;
    case 11:
      // regular state 7
      lcd_cmd8( 0x0C0, ROW_L );   // cursor second row home
      for( loop = 0; loop <= 19; loop++ ) 
        lcd_data8( BufLCD[ 3 ][ loop ], ROW_L );
      subState_LCD = 12;
      break;
    case 12:
      // regular state 8
      for( loop = 20; loop <= 39; loop++ ) 
        lcd_data8( BufLCD[ 3 ][ loop ], ROW_L );
//      lcd_wait( F_SHORT );
      subState_LCD = 13;
      break;
    case 13:
      // regular state 9
      subState_LCD = 5;
      break;
    default:
      // to init state 1
      subState_LCD = 0;
      break;
  }
}

void lcd_wait( char flag_long )
{
  __disable_interrupt();
  LcdWait = 0;
  __enable_interrupt();

  if( flag_long == F_LONG )
  {
    while( 1 )
    {
      if( LcdWait >= 5 ) break;
    }
  }
  else
  {
    while( 1 )
    {
      if( LcdWait >= 1 ) break;
    }
  }
}

void lcd_cmd8( unsigned char command, unsigned char hl )
{
  // 8bit command send
  LCDC_OUT &= ~LCD_RS;  // H->L
  LCDD_OUT = command;

  if( hl == ROW_H )
  {
    LCDC_OUT |= LCD_E1; // L->H
    LCDC_OUT &= ~LCD_E1; // H->L
  }
  else
  {
    LCDC_OUT |= LCD_E2; // L->H
    LCDC_OUT &= ~LCD_E2; // H->L
  }

  lcd_wait( 0 );
}

void lcd_data8( unsigned char data, unsigned char hl )
{
  // 8bit command send
  LCDC_OUT |= LCD_RS;  // L->H
  LCDD_OUT = data;
  if( hl == ROW_H )
  {
    LCDC_OUT |= LCD_E1; // L->H
    LCDC_OUT &= ~LCD_E1; // H->L
  }
  else
  {
    LCDC_OUT |= LCD_E2; // L->H
    LCDC_OUT &= ~LCD_E2; // H->L
  }

  lcd_wait( 0 );
}

void byte2nibbles( void )
{
  b2n.nibbles[ MSB ] = b2n.data >> 4;
  b2n.nibbles[ MSB ] &= 0x0F;
  if( b2n.nibbles[ MSB ] < 10 )
  {
    b2n.nibbles[ MSB ] += '0';
  }
  else
  {
    b2n.nibbles[ MSB ] += 'A' - 10;
  }

  b2n.nibbles[ LSB ] = b2n.data & 0x0F;
  if( b2n.nibbles[ LSB ] < 10 )
  {
    b2n.nibbles[ LSB ] += '0';
  }
  else
  {
    b2n.nibbles[ LSB ] += 'A' - 10;
  }
}
