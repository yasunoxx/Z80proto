/*
 * io.h -- SPI and 40x4 Char. LCD for MSP430G2553
 * (C)2025 by yasunoxx▼Julia
 * ### Use TI-MSPGCC6.1.1.0 or above version ###
 */

#define	LED1		BIT0
#define	LED_DIR		P1DIR
#define	LED_OUT		P1OUT

/* io.c */
extern void InitializeIOpins( void );
extern void ConfigureAdcTempSensor( void );
extern unsigned short SampleAndConversionAdcTemp( void );
extern volatile unsigned short TempReg;
