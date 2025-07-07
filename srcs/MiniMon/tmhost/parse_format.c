// parse_format.c
#include <stdint.h>
#include "control.h"
#include "parse.h"

#ifdef _TMHOST_
const uint8_t TxFormat[ 8 ][ 80 ] = {
    // Start Linkup
    {
           8,
         SYN,  PAD, PAD, PAD, PAD, PAD, PAD, PAD,  ENQ
    },
    // No Operation/Keep Alive
    {
           8,
         SYN, 0xA5, PAD, PAD, PAD, PAD, PAD, PAD,  ENQ
    },
    // Set Breakpoint
    {
           8,
         SYN,  'B',  'P',    0,    0, 0x00, 0x00,  ENQ
    //   SYN   'B'   'P' {Num.}      {Address}
    },
    // Register Previous Breakpoint
    {
           8,
         SYN,  'R',  'E',  'G',    0,  PAD,  PAD,  ENQ
    },
    // Write Memory 64bytes
    {
          72,
         SYN,  'W',  'M',   64,   64, 0x00, 0x00,  ENQ,
        //00,  +01,  +02,  +03,  +04,  +05, + 06,  +07
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        //08
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        //10
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        //18
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        //20
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        //28
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        //30
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        //38
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    },
    // Read Memory 64bytes
    {
           8,
         SYN,  'R',  'M',   64,   64, 0x00, 0x00,  ENQ
    },
    // Write Memory 1byte
    {
           8,
         SYN,  'W',  'M',    1,    1, 0x00, 0x00,  ENQ
    },
    // Read Memory 1byte
    {
           9,
         SYN,  'R',  'M',    1,    1, 0x00, 0x00,  ENQ,
        //00
        0x00
    }
    // Inport
    // Outport
    // Run with Trace
    // Stop Run & Trace
};
#endif // _TMHOST_

const uint8_t RxFormat[ 8 ][ 80 ] = {
    // Start Linkup
    {
           8,
         SYN,  PAD,  PAD,  PAD,  PAD,  PAD,  PAD,  ACK
    },
    // No Opertion/Keep Alive
    {
           8,
         SYN, 0x5A,  PAD,  PAD,  PAD,  PAD,  PAD,  ACK
    },
    // Set Breakpoint
    {
           8,
         SYN,  'B',  'P',    0,    0, 0x00, 0x00,  ACK
    //   SYN   'B'   'P' {Num.}      {Address}     ACK
    },
    // Register Previous Breakpoint
    {
          32,
         SYN,  'R',  'E',  'G',   24,  PAD,  PAD,  ACK,
        // or SYN, "REG", NUL
        // A,    F,    B,    C,    D,    E,    H,    L
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        //A',   F',   B',   C',   D',   E',   H',   L'
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        //      IX,         IY,         PC,         SP
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    },
    // Write Memory 64bytes
    {
           8,
         SYN,  'W',  'M',   64,   64, 0x00, 0x00,  ACK
    },
    // Read Memory 64bytes
    {
          72,
         SYN,  'R',  'M',   64,   64, 0x00, 0x00,  ACK,
        //00,  +01,  +02,  +03,  +04,  +05, + 06,  +07
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        //08
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        //10
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        //18
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        //20
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        //28
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        //30
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        //88
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    },
    // Write Memory byte
    {
           8,
         SYN,  'W',  'M',    1,    1, 0x00, 0x00,  ACK
    },
    // Read Memory 1byte
    {
          9,
         SYN,  'R',  'M',    1,    1, 0x00, 0x00,  ACK,
        //00
        0x00
    }
};
