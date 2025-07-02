CC = sdcc
AS = sdasz80
LD = sdldz80
TARGET = m_loader

ASMSRC = $(TARGET).asm
ASMOBJ = $(TARGET).rel
BIN = $(TARGET).bin
OBJS = $(ASMOBJ) command_j.o command_d.o command_m.o command_i.o \
	command_b.o command_p.o
#	lcdlib.rel \
#	command_t.o \
#	command_x.o xymodem.rel
MAP = $(TARGET).map
#ASFLAGS = -DWITH_XYMODEM=1 -DUSE_LCD=1 \
#	-DWITH_7SEG=0 -DWITH_SPI=1
CFLAGS = -mz80 --std-sdcc11 -DUSE_LCD=1 \
	--opt-code-size --stack-auto
LDFLAGS = --code-loc=$(CODELOC) --stack-loc=(STACKLOC) \
	--data-loc=$(DATALOC)
#	--portmode=z80
#	--out-gmt-elf
.PHONY:	all $(OBJS)

all: $(OBJS)
	$(AS) $(ASFLAGS) $(ASMSRC)
	$(LD) $(LDFLAGS) $(OBJS) -o $(BIN)

xymodem.o:
	$(CC) $(CFLAGS) -c xymodem.c

lcdlib.o:
	$(CC) $(CFLAGS) -c lcdlib.c

clean:
	rm -f $(BIN) $(OBJS) $(MAP) *.lis *.lst
