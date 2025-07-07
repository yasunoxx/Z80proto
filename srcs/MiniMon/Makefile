# adjust your environment
ADDRESS = 0D800h

CC = zcc
AS = z88dk-z80asm
DASM = z88dk-dis
TARGET = minimon
CP = cp
CAT = cat
RM = rm

ASMSRC = $(TARGET).asm
ASMOBJ = $(TARGET).o
BIN = $(TARGET).bin
OBJS = $(ASMOBJ) command_j.o command_d.o command_m.o command_i.o \
	command_b.o command_p.o command_f.o \
	command_t.o \
	command_x.o \
	parse_format.o crc.o testmode.o
#	lcdlib.o
#	xymodem.o

MAP = $(TARGET).map
ASFLAGS = -DWITH_XYMODEM=1 -DUSE_LCD=0 \
	-DWITH_7SEG=0 -DWITH_SPI=1
CFLAGS = +embedded -DUSE_LCD=0 -DCRC8
#	--opt-code-speed
#	-D__Z88DK_R2L_CALLING_CONVENTION
LDFLAGS = +embedded --no-crt -m
ASMFLAGS = -r$(ADDRESS) $(ASFLAGS)

.PHONY:	all $(OBJS)

all: $(OBJS)
	$(AS) $(ASMFLAGS) $(ASMSRC) -o$(ASMOBJ)
	$(CC) $(LDFLAGS) $(OBJS) -o $(BIN)
	$(DASM) -o $(ADDRESS) -x $(MAP) -s $(MAP) $(BIN) > $(TARGET).lst
	$(CP) ../ipl0/ipl0.bin ./$(BIN).rom
	$(CAT) $(BIN) >> $(BIN).rom

xymodem.o:
	$(CC) $(CFLAGS) -c xymodem.c

lcdlib.o:
	$(CC) $(CFLAGS) -c lcdlib.c

testmode.o:
	$(CC) $(CFLAGS) -c testmode.c

parse_format.o:
	$(CP) tmhost/parse_format.c .
	$(CP) tmhost/parse.h .
	$(CP) tmhost/control.h .
	$(CC) $(CFLAGS) -c parse_format.c

crc.o:
	$(CP) tmhost/crc8-ccitt.c .
	$(CC) $(CFLAGS) -c crc8-ccitt.c -o crc.o

clean:
	$(RM) -f $(BIN) $(OBJS) $(MAP) *.lis *.lst *.sym *.rom
	$(RM) -f parse_format.c parse.h control.h
	$(RM) -f crc8-ccitt.c
