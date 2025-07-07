#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#include <ftd2xx.h> // libftd2xx
#include "control.h"
#include "parse.h"

extern uint8_t calcCRC8CCITT( uint8_t crc, uint8_t buf );

uint8_t RxBuffer[ 256 ], TxBuffer[ FIFO_PACKET_SIZE ];

int tm_main( void );
bool tm_Purge( FT_HANDLE ftHandle );
int16_t tm_SetFIFO( FT_HANDLE ftHandle );
int16_t tm_GetFIFO( FT_HANDLE ftHandle );
void tm_Closing( FT_HANDLE ftHandle );
FT_HANDLE tm_InitDevice();
#define tm_ResetDevice( x ) FT_ResetDevice( x ) // FT_STATUS tm_ResetDevice( FT_HANDLE )

int main( int argc, char **argv )
{
    uint8_t loop;

    // set startup
    TxBuffer[ 0 ] = STX;
    TxBuffer[ 1 ] = 0x0BE;
    TxBuffer[ 2 ] = 0x0EF;
    for( loop = 0; loop < 80; loop++ )
    {
        TxBuffer[ loop + 3 ] = 0;
    }

#ifdef CRC16
    crc = 0;
    for( loop = 0; loop <= FIFO_TRAILER_SIZE; loop++ )
    {
        TxBuffer[ loop + 3 ] = TxFormat[ START ][ loop + 1 ];
        crc = calc_crc( crc, TxBuffer[ loop + 3 ] );
    }
#if TARGET_LITTLE_ENDIAN
    TxBuffer[ loop + 4 ] = ( crc & 0x00FF );
    TxBuffer[ loop + 5 ] = ( crc >> 8 );
#else // TARGET_BIG_ENDIAN
    TxBuffer[ loop + 4 ] = ( crc >> 8 );
    TxBuffer[ loop + 5 ] = ( crc & 0x00FF );
#endif
    fprintf( stderr, "Generated TxBuffer[], CRC16:%02X%02X\r\n",
        TxBuffer[ loop + 4 ], TxBuffer[ loop + 5 ] );
#endif // CRC16
#ifdef CRC8
    uint8_t crc8 = 0;
    for( loop = 0; loop <= FIFO_TRAILER_SIZE; loop++ )
    {
        TxBuffer[ loop + 3 ] = TxFormat[ START ][ loop + 1 ];
        crc8 = calcCRC8CCITT( crc8, TxBuffer[ loop + 3 ] );
    }
    TxBuffer[ loop + 4 ] = crc8;
    fprintf( stderr, "Generated TxBuffer[], CRC8:%02X\r\n",
        TxBuffer[ loop + 4 ] );
#endif // CRC8

    TxBuffer[ loop + 6 ] = ETX;

    return tm_main();
}

int tm_main()
{
    FT_HANDLE ftHandle;
    FT_STATUS ftStatus;

    fprintf( stderr, "tmhost: Hello, 31337.\n" );
    ftHandle = tm_InitDevice();
    ftStatus = tm_ResetDevice( ftHandle );

    fprintf( stderr, "tmhost: Written %d bytes.\n", tm_SetFIFO( ftHandle ) );

    tm_Closing( ftHandle );

    return 0;
}

FT_HANDLE tm_InitDevice()
{
    FT_HANDLE ftHandle;
    FT_STATUS ftStatus = FT_OpenEx( ( PVOID )"FT245R USB FIFO",
                                    FT_OPEN_BY_DESCRIPTION, &ftHandle );
    if( ftStatus != FT_OK )
    {
        fprintf( stderr, "*Error: at FT_OpenEx() -- Check FT245R device connection.\n" );
        fprintf( stderr, "*Error: if unloaded ftdi_sio, try \"sudo rmmod ftdi_sio\" .\n");
    // FT_Open failed
        exit( 1 );
    }
    fprintf( stderr, "tmhost: FT245R open succeed.\n" );

    ftStatus = FT_SetLatencyTimer( ftHandle, 255 );

    return ftHandle;
}

void tm_Closing( FT_HANDLE ftHandle )
{
    FT_Close( ftHandle );
    fprintf( stderr, "tmhost: FT245R close.\n" );
}

int16_t tm_GetFIFO( FT_HANDLE ftHandle )
{
    FT_STATUS ftStatus;
    DWORD RxBytes;
    DWORD BytesReceived;

    FT_GetQueueStatus( ftHandle, &RxBytes );
    // or FT_GetStatus( ftHandle, &RxBytes, &TxBytes, &Event );
    if( RxBytes > 0 )
    {
        ftStatus = FT_Read( ftHandle, RxBuffer, RxBytes, &BytesReceived );
        if( ftStatus == FT_OK )
        {
            return ( int16_t )RxBytes;
        }
        else
        {
            return -1;
        }
    }
    return 0;
}

int16_t tm_SetFIFO( FT_HANDLE ftHandle )
{
    FT_STATUS ftStatus;
    DWORD BytesWritten;

    ftStatus = FT_Write(ftHandle, TxBuffer, sizeof(TxBuffer), &BytesWritten);
    if( ftStatus == FT_OK )
    {
        return ( int16_t )BytesWritten;
    }
    else
    {
        return -1;
    }
}

bool tm_Purge( FT_HANDLE ftHandle )
{
    FT_STATUS ftStatus;
    bool stat;

    while( 1 )
    {
        ftStatus = FT_StopInTask(ftHandle);
        if(ftStatus == FT_OK) break;
    }

    ftStatus = FT_Purge( ftHandle, FT_PURGE_RX | FT_PURGE_TX ); // Purge both Rx and Tx buffers
    if( ftStatus == FT_OK )
    {
        stat = true;
    }
    else
    {
        stat = false;
    }

    while( 1 )
    {
        ftStatus = FT_RestartInTask(ftHandle);
        if(ftStatus == FT_OK) break;
    }

    return stat;
}
