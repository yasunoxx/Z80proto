#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#include <syslog.h> 
#include <time.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <ftd2xx.h> // libftd2xx
#include "control.h"
#include "parse.h"

extern uint8_t calcCRC8CCITT( uint8_t crc, uint8_t buf );

//
uint8_t RxBuffer[ 256 ], TxBuffer[ FIFO_PACKET_SIZE ];
uint8_t *Buf_Memory;
char Buf_Mes[ 80 ];
//
uint16_t SequenceNum;
uint16_t DestAddr;
uint16_t DownUpLength;
uint8_t Wm64[ 64 ];
uint8_t Wm64_Size;
uint8_t Wm01;
bool F_Break;
uint16_t BreakPoint;
bool F_Trace;

//
int16_t tm_main( void );

bool tm_setTxBuffer( uint8_t cmd );
void tm_setTxBuffer_address( uint16_t Addr );
void tm_setTxBuffer_nbytes( uint8_t *data64, uint8_t size );
#define tm_setTxBuffer_64bytes(x) tm_setTxBuffer_nbytes(x,64)
void tm_setTxBuffer_1byte( uint8_t data );
void tm_setTxBuffer_Break( bool flag );
int16_t tm_SetFIFO( FT_HANDLE ftHandle );

//int16_t tm_GetFIFO( FT_HANDLE ftHandle );
int16_t tm_GetFIFO( FT_HANDLE ftHandle, uint16_t timeout );
void tm_DumpRxBuffer( uint8_t *buf );

FT_HANDLE tm_InitDevice();
#define tm_ResetDevice( x ) FT_ResetDevice( x ) // FT_STATUS tm_ResetDevice( FT_HANDLE )
void tm_Closing( FT_HANDLE ftHandle );
bool tm_Purge( FT_HANDLE ftHandle );


int main( int argc, char **argv )
{
    int16_t retval;

    #ifdef USE_STDERR
        openlog( "tmhost", LOG_NOWAIT | LOG_PERROR , LOG_DEBUG );
    #else
        openlog( "tmhost", LOG_NOWAIT, LOG_DEBUG );
    #endif
    setlogmask( LOG_DEBUG );

    sprintf( Buf_Mes, "Hello, 31337." );
    syslog( LOG_DEBUG, "%s", Buf_Mes );
    #ifndef USE_STDERR
        fprintf( stderr, "%s\n", Buf_Mes );
    #endif

    Buf_Memory = ( uint8_t * )malloc( 65536 );
    // For debug: checking Buf_Memory
    Buf_Memory[ 0x8000 ] = 0x00;
    SequenceNum = 0x0BEEF;

    F_Break = false;
    F_Trace = false;

    retval = tm_main();
    free( Buf_Memory );
    return ( int )retval;
}

int16_t tm_main()
{
    FT_HANDLE ftHandle;
    FT_STATUS ftStatus;

    ftHandle = tm_InitDevice();
    ftStatus = tm_ResetDevice( ftHandle );

//    tm_setTxBuffer( START );
//    tm_SetFIFO( ftHandle );

    int16_t result;
    while( 1 )
    {
        result = Command();
        switch( result )
        {
            case -32767:
//                tm_Closing( ftHandle );
//                return 0;   // exit
                tm_setTxBuffer( QUIT );
                break;
            case SET_BP:
                tm_setTxBuffer( SET_BP );
                tm_setTxBuffer_Break( F_Break );
                break;
            case START:
                tm_setTxBuffer( START );
                break;
            case -1:
            default:
                tm_setTxBuffer( NOP );
                break;
        }
main_try:
        tm_SetFIFO( ftHandle );
        usleep( 500000 );
        {
            uint16_t getsize = tm_GetFIFO( ftHandle, 3000 );

            if( getsize > FIFO_PACKET_SIZE )
            {
                uint16_t loop, offset;
                for( offset = 0; offset < getsize; offset++ )
                {
                    if( RxBuffer[ offset ] == STX )
                    {
                        // adjust offset
                        for( loop = 0; loop < FIFO_PACKET_SIZE; loop++ )
                        {
                            RxBuffer[ loop ] = RxBuffer[ loop + offset ];
                        }
                        break;
                    }
                }
            }
        }
        usleep( 250000 );
        tm_Purge( ftHandle );
//        tm_DumpRxBuffer( RxBuffer );
        if( true == Check_RxBuffer( RxBuffer ) )
        {
            SequenceNum++;
            if( result == -32767 )
            {
                tm_Closing( ftHandle );
                return 0; // exit
            }
        }
        else
        {
            goto main_try; // retry
        }
    }
}


// ==============================================
// Tx
// ==============================================
void tm_setTxBuffer_address( uint16_t addr )
{
        TxBuffer[ 8 ] = ( addr >> 8 );
        TxBuffer[ 9 ] = ( addr & 0x00FF );
}

void tm_setTxBuffer_seq( uint16_t seq )
{
        TxBuffer[ 1 ] = ( seq >> 8 );
        TxBuffer[ 2 ] = ( seq & 0x00FF );
}

void tm_setTxBuffer_nbytes( uint8_t *buf, uint8_t size )
{
    uint8_t loop;
    for( loop = 0; loop < size; loop++ )
    {
        TxBuffer[ loop + 11 ] = buf[ loop ];
    }
    TxBuffer[ 7 ] = size;   // max 64bytes(no check :-)
}

void tm_setTxBuffer_1byte( uint8_t buf )
{
    TxBuffer[ 11 ] = buf;
}

void tm_setTxBuffer_Break( bool flag )
{
    if( flag == false )
    {
        TxBuffer[ 7 ] = 0;
    }
    else
    {
        TxBuffer[ 7 ] = 1;
    }
}

bool tm_setTxBuffer( uint8_t cmd )
{
    uint8_t loop;

    // set template
    TxBuffer[ 0 ] = STX;
    tm_setTxBuffer_seq( SequenceNum );
    for( loop = 0; loop <= FIFO_TRAILER_SIZE; loop++ )
    {
        TxBuffer[ loop + 3 ] = TxFormat[ cmd ][ loop + 1 ];
    }

    switch( cmd )
    {
        case START:
            break;
        case NOP:
            break;
        case SET_BP:
            tm_setTxBuffer_address( BreakPoint );
            break;
        case REG:
            break;
        case WM64:
//            tm_setTxBuffer_address( DestAddr );
//            tm_setTxBuffer_64bytes( Wm64 );
            break;
        case RM64:
//            tm_setTxBuffer_address( DestAddr );
            break;
        case WM01:
//            tm_setTxBuffer_address( DestAddr );
//            tm_setTxBuffer_1byte( Wm01 );
            break;
        case RM01:
//            tm_setTxBuffer_address( DestAddr );
            break;
        case QUIT:
            break;
        default:
            return false;
    }

    uint8_t crc8 = 0;
    for( loop = 0; loop <= FIFO_TRAILER_SIZE; loop++ )
    {
        crc8 = calcCRC8CCITT( crc8, TxBuffer[ loop + 3 ] );
    }
    TxBuffer[ loop + 4 ] = 0;       // IDX_CRCH
    TxBuffer[ loop + 5 ] = crc8;    // IDX_CRCL
    sprintf( Buf_Mes, "Generated TxBuffer[], CRC8:%02X", crc8 );
    syslog( LOG_DEBUG, "%s", Buf_Mes );
    #ifndef USE_STDERR
        fprintf( stderr, "%s\n", Buf_Mes );
    #endif
    TxBuffer[ loop + 6 ] = ETX;

    return true;
}

int16_t tm_SetFIFO( FT_HANDLE ftHandle )
{
    FT_STATUS ftStatus;
    DWORD BytesWritten;

    ftStatus = FT_Write(ftHandle, TxBuffer, sizeof(TxBuffer), &BytesWritten);
    if( ftStatus == FT_OK )
    {
        sprintf( Buf_Mes, "FIFO: Written %d bytes.", BytesWritten );
        syslog( LOG_DEBUG, "%s", Buf_Mes );
#ifndef USE_STDERR
        fprintf( stderr, "%s\n", Buf_Mes );
#endif
        return ( int16_t )BytesWritten;
    }
    else
    {
        return -1;
    }
}

// ==============================================
// Rx
// ==============================================
//int16_t tm_GetFIFO( FT_HANDLE ftHandle )
int16_t tm_GetFIFO( FT_HANDLE ftHandle, uint16_t timeout )
{
    uint16_t loop;
    FT_STATUS ftStatus;
    DWORD RxBytes;
    DWORD BytesReceived;

    struct timespec ts;
    clockid_t clkid;
    uint16_t prev_msec, brk_msec;
    intmax_t prev_sec, brk_sec;

    if( clock_gettime( CLOCK_REALTIME, &ts ) == -1 )
    {
        perror( "clock_gettime" );
        exit( EXIT_FAILURE );
    }

    ts.tv_nsec = 0; // FIXME: ... OMG ...
    if( clock_settime( CLOCK_REALTIME, &ts ) == -1 )
    {
        perror( "clock_settime" );
        exit( EXIT_FAILURE );
    }
    if( timeout < 999 )
    {
        prev_msec = ( unsigned long )ts.tv_nsec / 1000000L;
        brk_msec = prev_msec + timeout;
        if( brk_msec >= 1000 )
        {
            brk_msec -= 1000;
        }
    }
    else
    {
        prev_sec = ( intmax_t )ts.tv_sec;
        brk_sec = prev_sec + ( intmax_t )( timeout / 1000 );
    }

    while( 1 )
    {
        ftStatus = FT_GetQueueStatus( ftHandle, &RxBytes );
        // or FT_GetStatus( ftHandle, &RxBytes, &TxBytes, &Event );
        if( ftStatus == FT_OK && RxBytes >= FIFO_PACKET_SIZE )
        {
            fprintf( stderr, "FIFO: Receive %d bytes.\n", RxBytes );
            break;
        }
        clock_gettime( CLOCK_REALTIME, &ts );
        if( timeout < 1000 )
        {
            if( ( ts.tv_nsec / 1000000L ) >= brk_msec )
            {
                fprintf( stderr, "FIFO: Receive timed out(%d) .\n", RxBytes );
                return -1;
            }
        }
        else
        {
            if( ts.tv_sec >= brk_sec )
            {
                fprintf( stderr, "FIFO: Receive timed out(%d) .\n", RxBytes );
                return -1;
            }
        }
    }

    ftStatus = FT_Read( ftHandle, RxBuffer, RxBytes, &BytesReceived );
    if( ftStatus == FT_OK )
    {
        return ( int16_t )RxBytes;
    }
    else
    {
        return -1;
    }

    return 0;
}

void tm_DumpRxBuffer( uint8_t *buf )
{
    uint16_t loop, loop2;

    sprintf( ( char * )Buf_Mes, "RxBuffer:" );
    fprintf( stderr, "%s\n", Buf_Mes );
    for( loop = 0; loop < 256; loop++ )
    {
        for( loop2 = 0; loop2 < 16; loop2++ )
        {
            sprintf( ( char * )Buf_Mes, "%02X", buf[ loop++ ] );
            fprintf( stderr, "%s", Buf_Mes );
            if( loop2 == 3 || loop2 == 7 || loop2 == 11 )
            {
                fprintf( stderr, " " );
            }
        }
        loop--;
        sprintf( ( char * )Buf_Mes, "\n" );
        fprintf( stderr, "%s", Buf_Mes );
    }
}

// ==============================================
// Misc
// ==============================================
FT_HANDLE tm_InitDevice()
{
    FT_HANDLE ftHandle;
    FT_STATUS ftStatus = FT_OpenEx( ( PVOID )"FT245R USB FIFO",
                                    FT_OPEN_BY_DESCRIPTION, &ftHandle );
    if( ftStatus != FT_OK )
    {
        sprintf( Buf_Mes, "*Error: at FT_OpenEx() -- Check FT245R device connection." );
        syslog( LOG_DEBUG, "%s", Buf_Mes );
        #ifndef USE_STDERR
            fprintf( stderr, "%s\n", Buf_Mes );
        #endif
        sprintf( Buf_Mes, "*Error: if unloaded ftdi_sio, try \"sudo rmmod ftdi_sio\" .");
        syslog( LOG_DEBUG, "%s", Buf_Mes );
        #ifndef USE_STDERR
            fprintf( stderr, "%s\n\n", Buf_Mes );
        #endif
        // FT_Open failed
        return 0;;
    }
    sprintf( Buf_Mes, "FT245R open succeed.\n" );
    syslog( LOG_DEBUG, "%s", Buf_Mes );

    ftStatus = FT_SetLatencyTimer( ftHandle, 255 );

    return ftHandle;
}

void tm_Closing( FT_HANDLE ftHandle )
{
    FT_Close( ftHandle );
    sprintf( Buf_Mes, "FT245R close.\n" );
    syslog( LOG_DEBUG, "%s", Buf_Mes );
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
