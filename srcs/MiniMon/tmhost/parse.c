// parse.c
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include "control.h"
#include "parse.h"

#ifdef _TMHOST_
struct disRx Now_disRx;

extern uint8_t RxBuffer[ 256 ], TxBuffer[ FIFO_PACKET_SIZE ];

void copy_RxBuffer( uint8_t *praw, uint8_t *buf )
{
    uint8_t loop;

    for( loop = 0; loop < sizeof( struct disRx ); loop++ )
    {
        praw[ loop ] = buf[ loop ];
    }
}

bool parse_disRx( struct disRx *pDisRx )
{
    bool result = true;

    if( pDisRx->stx == STX )
    {
        fprintf( stderr, "STX " );
    }
    else
    {
        fprintf( stderr, "*%02X ", pDisRx->stx );
        result = false;
    }
    fprintf( stderr, "#%04X ", ( pDisRx->frameid[ 0 ] << 8 ) | pDisRx->frameid[ 1 ] );

    if( pDisRx->syn == SYN )
    {
        fprintf( stderr, "SYN " );
    }
    else
    {
        fprintf( stderr, "*%02X ", pDisRx->syn );
        result = false;
    }
    fprintf( stderr, "#%1C #%1C ", pDisRx->cmd[ 0 ], pDisRx->cmd[ 1 ] );

    if( pDisRx->cmd[ 1 ] == 'M' || pDisRx->cmd[ 1 ] == 'P' )
    {
        fprintf( stderr, ">%02d ", pDisRx->cmd[ 2 ] );
        fprintf( stderr, "L%02d ", pDisRx->length );

        fprintf( stderr, "A%04X ", ( pDisRx->result[ 0 ] << 8 ) | pDisRx->result[ 1 ] );
        if( pDisRx->result[ 2 ] == ACK )
        {
            fprintf( stderr, "ACK ... " );
        }
        else
        {
            fprintf( stderr, "NAK ... " );
        }
    }
    else if( pDisRx->cmd[ 0 ] == 0x0A5 )
    {
        fprintf( stderr, "NOP PAD ... " );
        if( pDisRx->result[ 2 ] == ACK )
        {
            fprintf( stderr, "ACK ... " );
        }
        else
        {
            fprintf( stderr, "NAK ... " );
        }
    }
    else
    {
        fprintf( stderr, "#%1C ", pDisRx->cmd[ 2 ] );
        fprintf( stderr, "L%02d ", pDisRx->length );
        if( pDisRx->result[ 2 ] == ACK )
        {
            fprintf( stderr, "ACK ... " );
        }
        else
        {
            fprintf( stderr, "NAK ... " );
        }
    }

    fprintf( stderr, "#%04X ", ( pDisRx->crc[ 0 ] << 8 ) | pDisRx->crc[ 1 ] );
    if( pDisRx->etx == ETX )
    {
        fprintf( stderr, "ETX\r\n" );
    }
    else
    {
        fprintf( stderr, "*%02X\r\n", pDisRx->etx );
        result = false;
    }

    return result;
}

int16_t get_RxType( uint8_t *buf )
{
    int16_t type = -1;
    uint8_t loop;

    if( buf[ 0 ] == SYN )
    {
    }
    else
    {
        return -1;
    }

    for( loop = 0; loop <= QUIT; loop++ )
    {
        if( buf[ 1 ] == RxFormat[ loop ][ 2 ] )
        {
            type = RxFormat[ loop ][ 2 ];
            break;
        }
    }

    return type;
}

bool Check_RxBuffer( uint8_t *buf )
{
    copy_RxBuffer( ( uint8_t * )&Now_disRx, buf );
    return parse_disRx( &Now_disRx );
}


// for Debug
uint8_t ParseTxBuf( uint8_t index )
{
    uint8_t length = TxFormat[ index ][ 0 ];
    fprintf( stderr, "TxFormat[%d] is %d\n", index, length );
    uint8_t loop = 0;
    uint16_t sum = 0;

    TxBuffer[ loop++ ] = STX;
    while( 1 )
    {
        TxBuffer[ loop ] = TxFormat[ index ][ loop ];
//        sum += ( uint16_t )TxFormat[ index ][ loop ];
        loop++;
        if( loop > length )
        {
            break;
        }
    }
    TxBuffer[ loop++ ] = ( sum & 0x00FF );
    TxBuffer[ loop ] = ETX;

    return loop + 1;
}
#endif // _TMHOST_
