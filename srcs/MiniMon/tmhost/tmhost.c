#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>

#include <ftd2xx.h> // libftd2xx

char RxBuffer[ 256 ], TxBuffer[ 256 ];

// FT_STATUS tm_ResetDevice( FT_HANDLE )
#define tm_ResetDevice FT_ResetDevice

FT_HANDLE tm_InitDevice()
{
    FT_HANDLE ftHandle;
    FT_STATUS ftStatus = FT_OpenEx( ( PVOID )"FT245R USB FIFO",
                                    FT_OPEN_BY_DESCRIPTION, &ftHandle );
    if( ftStatus != FT_OK )
    {
        fprintf( stderr, "Error : Check FT245R device connection.\n" );
        // FT_Open failed
        exit( 1 );
    }

    ftStatus = FT_SetLatencyTimer( ftHandle, 255 );

    return ftHandle;
}

void tm_Closing( FT_HANDLE ftHandle )
{
    FT_Close( ftHandle );
    fprintf( stderr, "System:Close.\n" );
    exit( 0 );
}

bool tm_GetFIFO( FT_HANDLE ftHandle )
{
    FT_STATUS ftStatus;
    DWORD RxBytes;
    DWORD BytesReceived;
    bool stat;

    FT_GetQueueStatus( ftHandle, &RxBytes );
    // or FT_GetStatus( ftHandle, &RxBytes, &TxBytes, &Event );
    if( RxBytes > 0 )
    {
        ftStatus = FT_Read( ftHandle, RxBuffer, RxBytes, &BytesReceived );
        if( ftStatus == FT_OK )
        {
            stat = true;
        }
        else
        {
            stat = false;
        }
    }

    return stat;
}

bool tm_Purge( FT_HANDLE ftHandle )
{
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
