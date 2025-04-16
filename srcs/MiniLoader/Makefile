CC = zcc
TARGET = m_loader
CFLAGS = +embedded --no-crt m_loader.asm --list -m

SRC = $(TARGET).asm
OBJ = $(TARGET).bin
LST = $(TARGET).lis
MAP = $(TARGET).map
SYM = $(TARGET).sym

all: $(SRC)
	$(CC) $(CFLAGS) -o $(OBJ)

clean:
	rm -f $(OBJ) $(LST) $(MAP) $(SYM)
