CC = zcc
AS = z88dk-z80asm
TARGET = freertos

PATH_FREEOS_KERNEL_SOURCE = ../../../FreeRTOS-LTS/FreeRTOS/FreeRTOS-Kernel
FREERTOS_SRC = $(PATH_FREEOS_KERNEL_SOURCE)
ASMSRC = $(TARGET)_crt0.asm
ASMOBJ = $(TARGET).o
BIN = $(TARGET).bin
OBJS = $(ASMOBJ) main.o \
	croutine.o event_groups.o list.o tasks.o queue.o timers.o \
	heap_1.o \
	port.o

MAP = $(TARGET).map
CFLAGS = +embedded \
	-I$(PATH_FREEOS_KERNEL_SOURCE)/include \
	-I/usr/local/z88dk/include \
	-Iport
LDFLAGS = +embedded --no-crt -m -Llib2 -lembedded_clib2

# adjust your environment
ASFLAGS = -r1000h

.PHONY:	all $(OBJS)

all:
	$(CC) $(CFLAGS) -c main.c

	$(CC) $(CFLAGS) -c $(FREERTOS_SRC)/croutine.c -o croutine.o
	$(CC) $(CFLAGS) -c $(FREERTOS_SRC)/event_groups.c -o event_groups.o
	$(CC) $(CFLAGS) -c $(FREERTOS_SRC)/list.c -o list.o
	$(CC) $(CFLAGS) -c $(FREERTOS_SRC)/queue.c -o queue.o
	$(CC) $(CFLAGS) -c $(FREERTOS_SRC)/tasks.c -o tasks.o
	$(CC) $(CFLAGS) -c $(FREERTOS_SRC)/timers.c -o timers.o
	$(CC) $(CFLAGS) -c $(FREERTOS_SRC)/portable/MemMang/heap_1.c -o heap_1.o

	$(CC) $(CFLAGS) -c port/port.c -o port.o

	$(AS) $(ASFLAGS) $(ASMSRC) -o$(ASMOBJ)
	$(CC) $(LDFLAGS) $(OBJS) -o $(BIN)

clean:
	rm -f $(BIN) $(OBJS) *.o $(MAP)
