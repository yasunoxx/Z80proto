#include <stdio.h>
#include <stdint.h>
#include <limits.h> // CHAR_BIT 

#define MSB_CRCS (0x31) // x8 + x5 + x4 + 1

//static uint8_t calcCRC8CCITT(char *buff, size_t size)
uint8_t calcCRC8CCITT( uint8_t crc, uint8_t buf )
{
    uint8_t crc8 = crc;

    crc8 ^= buf;
	
        for(int idx=0; idx < CHAR_BIT; idx++) {
            if (crc8 & 0x80) {
                crc8 <<=1;
                crc8 ^= MSB_CRCS;
            } else {
                crc8 <<=1;
            }
        }

    return crc8;
}
