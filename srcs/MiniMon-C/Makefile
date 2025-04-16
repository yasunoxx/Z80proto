CC = zcc
AS = z88dk-z80asm
TARGET = minimon

ASMSRC = $(TARGET).asm
ASMOBJ = $(TARGET).o
BIN = $(TARGET).bin
OBJS = $(ASMOBJ) command_j.o command_d.o command_m.o \
 				command_p.o command_f.o csub_command_f.o \
				command_b.o
MAP = $(TARGET).map
DEF = $(TARGET).def
CFLAGS = +embedded
LDFLAGS = +embedded --no-crt -m -gpf:$(DEF) -Llib2 -lembedded_clib2

# adjust your environment
ASFLAGS = -r0E000h

.PHONY:	all $(OBJS)

all:
	$(CC) $(CFLAGS) -c csub_command_f.c
	$(AS) $(ASFLAGS) $(ASMSRC) -o$(ASMOBJ)
	$(CC) $(LDFLAGS) $(OBJS) -o $(BIN)

clean:
	rm -f $(BIN) $(OBJS) $(MAP) $(DEF)
