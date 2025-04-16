/*
 * spi_target.c -- SPI and 40x4 Char. LCD for MSP430G2553
 * (C)2021,2022,2025 by yasunoxx▼Julia
 * ### Use TI-MSPGCC6.1.1.0 or above version ###
 */

/* Original Source Copyright and usage */
//******************************************************************************
//   MSP430G2xx3 Demo - USCI_B0, SPI 3-Wire Master multiple byte RX/TX
//
//   Description: SPI master communicates to SPI slave sending and receiving
//   3 different messages of different length. SPI master will enter LPM0 mode
//   while waiting for the messages to be sent/receiving using SPI interrupt.
//   SPI Master will initially wait for a port interrupt in LPM0 mode before
//   starting the SPI communication.
//   ACLK = NA, MCLK = SMCLK = DCO 16MHz.
//
//   Nima Eskandari
//   Texas Instruments Inc.
//   April 2017
//   Built with CCS V7.0
//
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
#include "spi_target.h"
#include "lcd.h"

#define	INITSTAT_BUSY	0x80
#define	INITSTAT_READY	0
extern  volatile unsigned char F_InitStat;  // main.c

/* MasterTypeX are example buffers initialized in the master, they will be
 * sent by the master to the slave.
 * TargetTypeX are example buffers initialized in the slave, they will be
 * sent by the slave to the master.
 * */

uint8_t MasterType0 [TYPE_M0_LENGTH] = { 0 };
uint8_t MasterType1 [TYPE_M1_LENGTH] = { 0 };
uint8_t MasterType2 [TYPE_M2_LENGTH] = { 0 };

uint8_t TargetType0 [TYPE_T0_LENGTH] = { NAK };
uint8_t TargetType1 [TYPE_T1_LENGTH] = { NAK };
uint8_t TargetType2 [TYPE_T2_LENGTH] = { NAK };

/* Used to track the state of the software state machine*/
SPI_Mode TargetMode = RX_REG_ADDRESS_MODE;

/* The Register Address/Command to use*/
uint8_t ReceiveRegAddr = 0;

/* ReceiveBuffer: Buffer used to receive data in the ISR
 * RXByteCtr: Number of bytes left to receive
 * ReceiveIndex: The index of the next byte to be received in ReceiveBuffer
 * TransmitBuffer: Buffer used to transmit data in the ISR
 * TXByteCtr: Number of bytes left to transfer
 * TransmitIndex: The index of the next byte to be transmitted in TransmitBuffer
 * */
uint8_t ReceiveBuffer[MAX_BUFFER_SIZE];
uint8_t RXByteCtr = 0;
uint8_t ReceiveIndex = 0;
uint8_t TransmitBuffer[MAX_BUFFER_SIZE];
uint8_t TXByteCtr = 0;
uint8_t TransmitIndex = 0;

/* Initialized the software state machine according to the received cmd
 *
 * cmd: The command/register address received
 * */
void SPI_Target_ProcessCMD(uint8_t cmd);

/* The transaction between the slave and master is completed. Uses cmd
 * to do post transaction operations. (Place data from ReceiveBuffer
 * to the corresponding buffer based in the last received cmd)
 *
 * cmd: The command/register address corresponding to the completed
 * transaction
 */
void SPI_Target_TransactionDone(uint8_t cmd);
void CopyArray(uint8_t *source, uint8_t *dest, uint8_t count);
void SendUCA0Data(uint8_t val);

void SPI_Target_ProcessCMD(uint8_t cmd)
{
    ReceiveIndex = 0;
    TransmitIndex = 0;
    RXByteCtr = 0;
    TXByteCtr = 0;

    switch (cmd)
    {
        case (CMD_TYPE_0_TARGET):   //Send slave stat (This device's id)
            BufLCD[ 3 ][ 0 ] = 'X';
            TargetMode = TX_DATA_MODE;
            TXByteCtr = TYPE_T0_LENGTH;
            //Fill out the TransmitBuffer
            TargetType0[ 0 ] = ACK;
            CopyArray(TargetType0, TransmitBuffer, TYPE_T0_LENGTH);
            //Send First Byte
            SendUCA0Data(TransmitBuffer[TransmitIndex++]);
            TXByteCtr--;
            break;
        case (CMD_TYPE_1_TARGET):   //Send slave device time (This device's time)
            TargetMode = TX_DATA_MODE;
            TXByteCtr = TYPE_T1_LENGTH;
            //Fill out the TransmitBuffer
            CopyArray(TargetType1, TransmitBuffer, TYPE_T1_LENGTH);
            //Send First Byte
            SendUCA0Data(TransmitBuffer[TransmitIndex++]);
            TXByteCtr--;
            break;
        case (CMD_TYPE_2_TARGET):   //Send slave device location (This device's location)
            TargetMode = TX_DATA_MODE;
            TXByteCtr = TYPE_T2_LENGTH;
            //Fill out the TransmitBuffer
            CopyArray(TargetType2, TransmitBuffer, TYPE_T2_LENGTH);
            //Send First Byte
            SendUCA0Data(TransmitBuffer[TransmitIndex++]);
            TXByteCtr--;
            break;
        case (CMD_TYPE_0_MASTER):
            TargetMode = RX_DATA_MODE;
            RXByteCtr = TYPE_M0_LENGTH;
            break;
        case (CMD_TYPE_1_MASTER):
            TargetMode = RX_DATA_MODE;
            RXByteCtr = TYPE_M1_LENGTH;
            break;
        case (CMD_TYPE_2_MASTER):
            TargetMode = RX_DATA_MODE;
            RXByteCtr = TYPE_M2_LENGTH;
            break;
        default:
            __no_operation();
            break;
    }
}


void SPI_Target_TransactionDone(uint8_t cmd)
{
    switch (cmd)
    {
        case (CMD_TYPE_0_TARGET): //Target device id was sent(This device's id)
            break;
        case (CMD_TYPE_1_TARGET): //Target device time was sent(This device's time)
            break;
        case (CMD_TYPE_2_TARGET): //Send slave device location (This device's location)
            break;
        case (CMD_TYPE_0_MASTER):
            CopyArray(ReceiveBuffer, MasterType0, TYPE_M0_LENGTH);
            break;
        case (CMD_TYPE_1_MASTER):
            CopyArray(ReceiveBuffer, MasterType1, TYPE_M1_LENGTH);
            break;
        case (CMD_TYPE_2_MASTER):
            CopyArray(ReceiveBuffer, MasterType2, TYPE_M2_LENGTH);
            break;
        default:
            __no_operation();
            break;
    }
}

void CopyArray(uint8_t *source, uint8_t *dest, uint8_t count)
{
    uint8_t copyIndex = 0;
    for (copyIndex = 0; copyIndex < count; copyIndex++)
    {
        dest[copyIndex] = source[copyIndex];
    }
}

void SendUCA0Data(uint8_t val)
{
    while (!(IFG2 & UCA0TXIFG));              // USCI_A0 TX buffer ready?
    UCA0TXBUF = val;
}

//******************************************************************************
// Device Initialization *******************************************************
//******************************************************************************

void InitClockTo16MHz()
{
    if (CALBC1_16MHZ==0xFF)                  // If calibration constant erased
    {
        while(1);                               // do not load, trap CPU!!
    }
    DCOCTL = 0;                               // Select lowest DCOx and MODx settings
    BCSCTL1 = CALBC1_16MHZ;                    // Set DCO
    DCOCTL = CALDCO_16MHZ;
}

void InitSPI()
{
    //Clock Polarity: The inactive state is high
    //MSB First, 8-bit, Slave, 3-pin mode, Synchronous
    UCA0CTL0 |= UCCKPL + UCMSB + UCMODE_2 + UCSYNC;
//    UCA0CTL1 |= UCSSEL_2;                     // SMCLK
//    UCA0BR0 |= 0x20;                          // /2
//    UCA0BR1 = 0;                              //
    UCA0MCTL = 0;                             // No modulation must be cleared for SPI
    UCA0CTL1 &= ~UCSWRST;                     // **Initialize USCI state machine**
    IE2 |= UCA0RXIE;                          // Enable USCI0 RX interrupt

    TARGET_CS_DIR |= TARGET_CS;
    TARGET_CS_IN |= TARGET_CS;
    //SPI Pins
    P1SEL |= BIT1 | BIT2 | BIT4;
    P1SEL2 |= BIT1 | BIT2 | BIT4;

    P1DIR |= TARGET_CS;
}

//******************************************************************************
// Main ************************************************************************
// Send and receive three messages containing the example commands *************
//******************************************************************************

#ifdef DEBUG
int main(void)
{
  WDTCTL = WDTPW + WDTHOLD;                 // Stop watchdog timer

  initClockTo16MHz();
  initGPIO();
  initSPI();

//  P1OUT &= ~BIT5;                           // Now with SPI signals initialized,
//  __delay_cycles(100000);
//  P1OUT |= BIT5;                            // reset slave
//  __delay_cycles(100000);                   // Wait for slave to initialize

//  P1OUT |= BIT0;

  __bis_SR_register(LPM0_bits + GIE);       // CPU off, enable interrupts

  SPI_Target_ReadReg(CMD_TYPE_2_TARGET, TYPE_T2_LENGTH);
  CopyArray(ReceiveBuffer, MasterType2, TYPE_T2_LENGTH);

  SPI_Target_ReadReg(CMD_TYPE_1_TARGET, TYPE_T1_LENGTH);
  CopyArray(ReceiveBuffer, MasterType1, TYPE_T1_LENGTH);

  SPI_Target_ReadReg(CMD_TYPE_0_TARGET, TYPE_T0_LENGTH);
  CopyArray(ReceiveBuffer, MasgetType0, TYPE_T0_LENGTH);

  SPI_Target_WriteReg(CMD_TYPE_2_TARGET, TargetType2, TYPE_T2_LENGTH);
  SPI_Target_WriteReg(CMD_TYPE_1_TARGET, TargetType1, TYPE_T1_LENGTH);
  SPI_Target_WriteReg(CMD_TYPE_0_TARGET, TargetType0, TYPE_T0_LENGTH);
  __bis_SR_register(LPM0_bits + GIE);
}
#endif // DEBUG

//******************************************************************************
// SPI Interrupt ***************************************************************
//******************************************************************************

void __attribute__ ((interrupt(USCIAB0RX_VECTOR))) USCIB0RX_ISR (void)
{
  uint8_t UCA0_rx_val = 0;
  if (IFG2 & UCA0RXIFG)
  {
    UCA0_rx_val = UCA0RXBUF;
    if (!(TARGET_CS_IN & TARGET_CS))
    {
        switch (TargetMode)
        {
          case (RX_REG_ADDRESS_MODE):
              ReceiveRegAddr = UCA0_rx_val;
              SPI_Target_ProcessCMD(ReceiveRegAddr);
              break;
          case (RX_DATA_MODE):
              ReceiveBuffer[ReceiveIndex++] = UCA0_rx_val;
              RXByteCtr--;
              if (RXByteCtr == 0)
              {
                  //Done Receiving MSG
                  TargetMode = RX_REG_ADDRESS_MODE;
                  SPI_Target_TransactionDone(ReceiveRegAddr);
              }
              break;
          case (TX_DATA_MODE):
              if (TXByteCtr > 0)
              {
                  SendUCA0Data(TransmitBuffer[TransmitIndex++]);
                  TXByteCtr--;
              }
              if (TXByteCtr == 0)
              {
                  //Done Transmitting MSG
                  TargetMode = RX_REG_ADDRESS_MODE;
                  SPI_Target_TransactionDone(ReceiveRegAddr);
              }
              break;
          default:
              __no_operation();
              break;
        }
    }
  }
}
