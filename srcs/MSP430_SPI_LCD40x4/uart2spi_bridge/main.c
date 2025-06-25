/* --COPYRIGHT--,BSD_EX
 * Copyright (c) 2017, Texas Instruments Incorporated
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * *  Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * *  Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * *  Neither the name of Texas Instruments Incorporated nor the names of
 *    its contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *******************************************************************************
 *
 *                       MSP430 CODE EXAMPLE DISCLAIMER
 *
 * MSP430 code examples are self-contained low-level programs that typically
 * demonstrate a single peripheral function or device feature in a highly
 * concise manner. For this the code may rely on the device's power-on default
 * register values and settings such as the clock configuration and care must
 * be taken when combining code from several examples to avoid potential side
 * effects. Also see www.ti.com/grace for a GUI- and www.ti.com/msp430ware
 * for an API functional library-approach to peripheral configuration.
 *
 * --/COPYRIGHT--*/
//******************************************************************************
//  MSP430FR2000 Demo - UART-to-SPI Bridge
//
//  Description: This example enables serial communication between a UART device
//  and a SPI device. The hardware SPI interface utilizes the
//  eUSCI_A module, and the software (SW) UART interface utilizes Timer_B.
//  Connect the SPI device to the SPI interface
//  (P1.5, P1.6 and P1.7), and connect the UART device to the
//  SW UART interface (P2.0 and P2.1). This example supports half-duplex
//  UART communication only, eight data bits with least significant bit first,
//  no parity bit, and one stop bit. After initializing everything, the CPU
//  waits in LPM0 to save power until a SPI or UART receive interrupt occurs.
// Then, the CPU exits LPM0, reads the SPI or UART data, transmits the data on
//  the other interface, and returns to LMP0.
//  ACLK = default REFO ~32768Hz, MCLK = SMCLK = 16MHz
//
//                               MSP430FR2000
//                           -------------------
//                       /|\|                   |
//                        | |                   |
//                        --|RST                |
//                          |                   |
//               SPI CLK <--|P1.5/UCA0CLK       |
//                          |                   |
//              SPI MISO -->|P1.6/UCA0SOMI  P2.0|--> SW UART TX Out
//                          |                   |
//              SPI MOSI <--|P1.7/UCA0SIMO  P2.1|<-- SW UART RX In
//                          |                   |
//                          |                   |
//
//
//  Nathan Siegel
//  Texas Instruments Inc.
//  Sept. 2017
//  Built with IAR Embedded Workbench v7.10.2 & Code Composer Studio v7.2.0
//******************************************************************************

#include <msp430g2553.h>
#include <stdint.h>
#include <stdbool.h>
#include "io.h"
#include "tlv.h"
#include "spi_target.h"
#include "lcd.h"

const char *FW_Version = "0X01";

// Define pins
#define SPI_MOSI_PIN  BIT7      // SPI transmit pin, P1.7
#define SPI_MISO_PIN  BIT6      // SPI receive pin,  P1.6
#define SPI_CLK_PIN BIT5      // SPI CLK pin, P1.5
#define SW_TX_PIN   BIT0      // SW UART transmit pin, P2.0
#define SW_RX_PIN   BIT1      // SW UART receive pin,  P2.1

// Define parameters
#define SW_WHOLE_BIT 1666   // Full bit time, units are in clock cycles
                            // SW_WHOLE_BIT = SMCLK/SW UART baud rate
                            //              = 16MHz/9600 baud, SMCLK = 16MHz
                            //              = 1666 cycles

#define SW_HALF_BIT  833    // Half bit time, units are in clock cycles
                            // SW_HALF_BIT = SW_WHOLE_BIT/2 = 1666/2
                            //             = 833 cycles

#define SW_TOTAL_BITS 9     // 1 start bit, 8 data bits, 1 stop bit

// Define states
#define SPI_RX_STATE 1       // HW SPI receive state
#define SW_RX_STATE 2       // SW UART receive state

// Declare global variables
#if defined (__TI_COMPILER_VERSION__)
volatile uint16_t tempByte;                    // Stores data byte
volatile uint8_t bitCounter;                   // Tracks number of bits
volatile unsigned char currentState;           // Used to indicate state

#elif defined (__IAR_SYSTEMS_ICC__)
__no_init volatile uint16_t tempByte;          // Stores data byte
__no_init volatile uint8_t bitCounter;         // Tracks number of bits
__no_init volatile unsigned char currentState; // Used to indicate state
#endif

#define TIMER_PWM_PERIOD 12
#define TIMER_PWM_PERIOD_DCO 12000
void ConfigureTimerPwm( void );
void PreApplicationMode( void );
void InitializeClocks( void );
void initializeDCO( void );
void InitializeLeds( void );

#define SYSTIMER_COUNTUP        100
volatile unsigned int SysTimer_Counter;
#define SYSTIMER2_COUNTUP       10
volatile unsigned int SysTimer2_Counter;
#define Low 0
#define High 1
volatile unsigned char ClockMode;

#define SYSTIMER_FLIP_OFF       0
#define SYSTIMER_FLIP_ON        1
volatile unsigned char F_SysTimer_Flipper;
#define SYSTIMER2_FLIP_OFF      0
#define SYSTIMER2_FLIP_ON       1
volatile unsigned char F_SysTimer2_Flipper;

// Declare functions
void ConfigureTimerPwm( void )
{
    if( ClockMode == Low )
    {
        TACCR0 = TIMER_PWM_PERIOD;          // Compare Maxim value
        #ifdef TARGET_XT1
            TACTL = TASSEL_2 | MC_1;        // TACLK = SMCLK, Up mode.
        #else
            TACTL = TASSEL_2 | MC_1;        // TACLK = ACLK, Up mode.
        #endif
        TACCTL0 = CCIE;                     // TACCTL0 output OUT bit(not used)
        TACCTL1 = CCIE + OUTMOD_3;          // TACCTL1 Capture Compare, Set/reset
    }
    else // ClockMode Low to High
    {
        TACCR0 = TIMER_PWM_PERIOD_DCO;      // Compare Maxim value
        TACTL = TASSEL_2 | MC_1;            // TACLK = SMCLK, Up mode.
        TACCTL0 = CCIE;                     // TACCTL0 output OUT bit(not used)
        TACCTL1 = CCIE + OUTMOD_3;          // TACCTL1 Capture Compare, Set/reset
    }                                              
}

void InitializeClocks( void )
{
    DCOCTL = 0;
    BCSCTL1 = 0;
    BCSCTL1 = XT2OFF | DIVA_0 | RSEL0;
                      // Set ACLK / 1
    BCSCTL2 = 0;
    BCSCTL2 = SELM_3 | DIVM_0 | SELS | DIVS_0;
                      // SMCLK = MCLK = ACLK = 12kHz
    BCSCTL3 = 0;
    BCSCTL3 = LFXT1S_2; // use VLO    
}

void initializeDCO( void )
{
        DCOCTL = Var_CALDCO_16MHz;
        DCOCTL |= DCO2;
        BCSCTL1 = Var_CALBC1_16MHz;
        BCSCTL1 |= DIVA_0;
        BCSCTL2 &= ~( DIVS_3 );
        BCSCTL2 = SELM_0 | DIVM_0; // DCO = MCLK = SMCLK = ACLK(12MHZ, VLO * 1000)
        TACTL = TASSEL_2 | MC_2 | TACLR;
      // Select SMCKL as source, no divider, Continuous mode and reset timer
        BCSCTL1 |= XT2OFF; // XT2 off, and Set ACLK to /1 divider

        ClockMode = High;
}

void PreApplicationMode( void )
{
        SysTimer_Counter = 0;
        F_SysTimer_Flipper = SYSTIMER_FLIP_OFF;
        SysTimer2_Counter = 0;
        F_SysTimer2_Flipper = SYSTIMER2_FLIP_OFF;
        ClockMode = Low;
//  __bis_SR_register( LPM3_bits + GIE );  // LPM0 with
//  __bis_SR_register( LPM3_bits );
}

// Main function
int main(void)
{
    WDTCTL = WDTPW | WDTHOLD;       // Stop watchdog timer
    ClockMode = Low;

    InitializeClocks();
    InitializeIOpins();
    PreApplicationMode();
    ConfigureTimerPwm();

    __enable_interrupt();
    ConfigureAdcTempSensor();
    GetTLV();
    __disable_interrupt();
    initializeDCO(); // on this file
    ConfigureTimerPwm();
    __enable_interrupt();

#ifdef FIXME
    // Initialize hardware UART pins
    P1SEL0 |= SPI_MISO_PIN | SPI_MOSI_PIN | SPI_CLK_PIN;      // Select SPI function

    // Initialize software UART pins, terminate unused GPIOs
    PADIR = 0xC1FF;                       // P2DIR = PADIR_H, P1DIR = PADIR_L
                                          // SW_TX_PIN (P2.0) = output
                                          // SW_RX_PIN (P2.1) = input

    PAOUT = 0x0100;                       // High (set UART idle state)
                                          // P2OUT = PAOUT_H, P1OUT = PAOUT_L
                                          // SW_TX_PIN (P2.0) = high

    P2IES |= SW_RX_PIN;                   // Select high-to-low interrupt edge
    P2IFG &= ~SW_RX_PIN;                  // Clear interrupt flag
    P2IE |= SW_RX_PIN;                    // Enable interrupt

    // Configure eUSCI_A SPI module
    UCA0CTLW0 = UCSWRST | UCSSEL__ACLK | UCMST | UCSYNC;  // Reset eUSCI
                                                           // Set SMCLK as BRCLK source
                                                           // Select master mode
                                                           // Enable Synchronous mode

    UCA0BRW = 0x0002;               // Bit rate clock = SMCLK/2 = 8 MHz

    UCA0CTLW0 &= ~UCSWRST;          // Release eUSCI_A UART module for operation
    UCA0IE = UCRXIE;                // Enable eUSCI_A RX interrupt
#endif

    // Enable global interrupts and enter LPM0
    __bis_SR_register(LPM0_bits + GIE);
}
