MSP430_SPI_LCD40x4
==================

SPI input, 40x4 Character LCD output for MSP430G2553.

Add new GCC(Mitto Systems Limited - msp430-gcc 9.2.0.50) support.
https://www.ti.com/tool/MSP430-GCC-OPENSOURCE

If you use old GCC, you must edit Makefile and interrupt func.

for usage:

    make
    mspdebug rf2500
      > prog main.elf
      > exit

and see sources and schematics.

※コレは、特にどうという事の無い実装ですわね。
