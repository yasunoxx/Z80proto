// parse.h -- header file for parse.h

#ifndef _PARSE_H_
#define _PARSE_H_

typedef struct disRx
{
    uint8_t stx;            // +1
    uint8_t frameid[ 2 ];       // +2 = 3

    uint8_t syn;            // +1 = 4( +1 )
    uint8_t cmd[ 3 ];       // +3 = 7( +3 = 4 )
    uint8_t length;         // +1 = 8( +1 = 5 )
    uint8_t result[ 3 ];    // +3 = 11( +3 = 8 )
    // if( cmd[1] != 'M' ) result + pad + pad; else address + result;
    uint8_t rxarray[ 72 ];  // +80 = 91( +72 = 80 )

    uint8_t crc[ 2 ];           // +2 = 93
    uint8_t etx;            // +1 = 94
} _disRx;

extern const uint8_t RxFormat[ 8 ][ 80 ];
#ifdef _TMHOST_
extern const uint8_t TxFormat[ 8 ][ 80 ];
extern uint8_t ParseTxBuf( uint8_t );
extern void Check_RxBuffer( uint8_t * );
#endif

// MAGIC NUMBER: FIFO_TRAILER_SIZE = 79, as BODY 79bytes
#define FIFO_TRAILER_SIZE 79
// MAGIC NUMBER: FIFO_PACKET_SIZE = 85, HEAD 3bytes + BODY 79bytes + TAIL 3bytes
#define FIFO_PACKET_SIZE 85

#define START   0   // Start Linkup
#define NOP     1   // No Operation/Keep Alive
#define SET_BP  2   // Set Breakpoint
#define REG     3   // Register Previous Breakpoint
#define WM64    4   // Write Memory 64bytes
#define RM64    5   // Read Memory 64bytes
#define WM01    6   // Write Memory 1 byte
#define RM01    7   // Read Memory 1 byte
#define INP     8   // Inport
#define OUTP    9   // Outport
#define TRACE   10  // Run with Trace
#define STOP    11  // Stop Run & Trace

#endif // _PARSE_H_
