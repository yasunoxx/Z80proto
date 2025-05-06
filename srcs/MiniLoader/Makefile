CC = zcc
AS = z88dk-z80asm
TARGET = m_loader

ASMSRC = $(TARGET).asm
ASMOBJ = $(TARGET).o
BIN = $(TARGET).bin
OBJS = $(ASMOBJ) command_j.o command_d.o command_m.o command_i.o
# kermit.o
MAP = $(TARGET).map
CFLAGS = +embedded
LDFLAGS = +embedded --no-crt -m -Llib2 -lembedded_clib2

.PHONY:	all $(OBJS)

all: $(OBJS)
	$(AS) $(ASFLAGS) $(ASMSRC) -o$(ASMOBJ)
	$(CC) $(LDFLAGS) $(OBJS) -o $(BIN)

kermit.o:
	$(CC) $(CFLAGS) -c kermit.c

clean:
	rm -f $(BIN) $(OBJS) $(MAP) *.lis
