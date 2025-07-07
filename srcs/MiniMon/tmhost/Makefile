TARGET = tmhost
CC = gcc
#ENDIAN = BIG_ENDIAN
ENDIAN = LITTLE_ENDIAN

# Define dependencies
DEP := -lftd2xx -lpthread -lrt
LDFLAGS := $(DEP) -Wl,-rpath=/usr/local/lib -L/usr/local/lib
CFLAGS = -I /usr/local/include $(DEP) -D_TMHOST_ -DTARGET_$(ENDIAN)
CFLAGS += -Wall -Wextra -DCRC8
OBJS = tmhost.o crc8-ccitt.o parse.o parse_format.o

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) -o $(TARGET) $(LDFLAGS)
clean:
	-rm -f $(OBJS) $(TARGET)
