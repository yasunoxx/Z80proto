// spi.c

// MSP430x543x_uscia0_spi_10.c original copyright:
/* --COPYRIGHT--,BSD_EX
 * Copyright (c) 2012, Texas Instruments Incorporated
 * All rights reserved.
 */

 //******************************************************************************
//   MSP430F54x Demo - USCI_A0, SPI 3-Wire Slave Data Echo
//
//   W. Goh
//   Texas Instruments Inc.
//   October 2008
//   Built with CCE Version: 3.2.2 and IAR Embedded Workbench Version: 4.11B

// and Modified by yasunoxx 2021/2022
//
//                   MSP430G2553
//                 -----------------
//            /|\ |                 |
//             |  |                 |
//             ---|RST          *RST|-> Target Reset (*RST)
//                |                 |
//                |             P1.2|-> Data Out (UCA0SIMO)
//                |                 |
//          LED <-|P1.7         P1.1|<- Data In (UCA0SOMI)
//                |                 |
//                |             P1.4|-> Serial Clock In (UCA0CLK)
//
//******************************************************************************

#include <msp430g2553.h>
#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include "spi_target.h"
#include "lcd.h"

volatile unsigned char F_SPI_Receive; // main.c
volatile unsigned char State_SPI_Receive;


unsigned char SPI_RxBuf[ SIZE_RXBUF ];
unsigned char SPI_RxBufWritePtr, SPI_RxBufReadPtr;

// int main(void)
void InitSPI()
{
  while( !( P1IN & 0x10 ) );                // If clock sig from mstr stays low,
                                            // it is not yet in SPI mode
  //SPI Pins
  P1SEL |= BIT1 | BIT2 | BIT4;
  P1SEL2 |= BIT1 | BIT2 | BIT4;

  UCA0CTL1 |= UCSWRST;                      // **Put state machine in reset**
  UCA0CTL0 |= UCSYNC+UCCKPL+UCMSB;          // 3-pin, 8-bit SPI slave,
                                            // Clock polarity high, MSB
  UCA0CTL0 |= UCMODE_2;                     // 4-pin STE low mode
  UCA0CTL1 &= ~UCSWRST;                     // **Initialize USCI state machine**

  SPI_RxBufWritePtr = 0;
  SPI_RxBufReadPtr = 0;
  State_SPI_Receive = STATE_INIT;

  IE2 |= UCA0RXIE;                       // Enable USCI_A0 RX interrupt
}

uint8_t CopyArray( unsigned char *source, unsigned char *dest, uint8_t count )
{
    uint8_t loop = 0;

    for( loop = 0; loop < count; loop++ )
    {
      if( dest[ loop ] == NUL ) break;
      dest[ loop ] = source[ loop ];
    }

    return loop;
}

unsigned char getchar_SPI()
{
  unsigned char val = NUL;

  if( SPI_RxBufReadPtr != SPI_RxBufWritePtr )
  {
    val = SPI_RxBuf[ SPI_RxBufReadPtr++ ];
    SPI_RxBufReadPtr &= SIZE_RXBUF - 1;
  }
  return val;
}

// Echo character
void __attribute__ ((interrupt(USCIAB0RX_VECTOR))) USCIAB0RX_ISR (void)
{
  switch(__even_in_range( IFG2, 4 ) )
  {
    case 0:break;                             // Vector 0 - no interrupt
    case 1:                                   // Vector 1 - UCA0RXIFG
      SPI_RxBuf[ SPI_RxBufWritePtr ] = UCA0RXBUF;
      SPI_RxBufWritePtr++;
      SPI_RxBufWritePtr &= SIZE_RXBUF - 1;
      while( !( UCA0STAT & UCBUSY ) );        // USCI_A0 TX buffer ready?
//      UCA0TXBUF = ACK;
      F_SPI_Receive = true;
      break;
      case 4:break;                             // Vector 4 - UCA1RXIFG
      default: break;
  }
}
