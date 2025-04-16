/*
 * io.c -- SPI and 40x4 Char. LCD for MSP430G2553
 * (C)2025 by yasunoxx▼Julia
 * ### Use TI-MSPGCC6.1.1.0 or above version ###
 */

#include <msp430g2553.h>
#include "io.h"

volatile unsigned short TempReg;

void ConfigureAdcTempSensor( void )
{
  /* Configure ADC Temp Sensor Channel */
  ADC10CTL1 = INCH_10 + ADC10DIV_3 + SHS_1;
  // Temp Sensor ADC10CLK/4, Timer_A.OUT1 Trigger
  ADC10CTL0 = SREF_1 + ADC10SHT_3 + REFON + REF2_5V + ADC10ON;  // + ADC10IE;
  ADC10CTL0 &= ~ADC10IFG;
  ADC10CTL0 |= ENC + ADC10SC;  // Sampling and conversion start
}

unsigned short SampleAndConversionAdcTemp( void )
{
  unsigned short tempreg;

  tempreg = ADC10MEM;
  ADC10CTL0 |= ENC + ADC10SC;         // Sampling and conversion start
  return tempreg;
}

void InitializeIOpins( void )
{
  P1SEL = 0x00;
  P1SEL2 = 0x00;
  P2SEL = 0x00;
  P2SEL2 = 0x00; // see MSP430x2xx manual Page 329

  LED_DIR |= LED1;
  LED_OUT &= ~LED1;
}

// ADC10 interrupt service routine
void __attribute__ (( interrupt ADC10_VECTOR )) ADC10_ISR( void )
{
  TempReg = ADC10MEM;
  ADC10CTL0 &= ~ADC10IFG;
  ADC10CTL0 |= ENC + ADC10SC;
}

// CS input pin interrupt
