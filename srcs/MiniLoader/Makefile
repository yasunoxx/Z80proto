CC = zcc
AS = z88dk-z80asm
TARGET = m_loader

ASMSRC = $(TARGET).asm
ASMOBJ = $(TARGET).o
BIN = $(TARGET).bin
OBJS = $(ASMOBJ) command_j.o command_d.o command_m.o command_i.o
MAP = $(TARGET).map
CFLAGS = +embedded
LDFLAGS = +embedded --no-crt -m

.PHONY:	all $(OBJS)

all:
	$(AS) $(ASFLAGS) $(ASMSRC) -o$(ASMOBJ)
	$(CC) $(LDFLAGS) $(OBJS) -o $(BIN)

clean:
	rm -f $(BIN) $(OBJS) $(MAP) *.lis
