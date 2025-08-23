TARGET = tmhost
CC = gcc

# Define dependencies
DEP := -lftd2xx -lpthread -lrt
LDFLAGS := $(DEP) -Wl,-rpath=/usr/local/lib -L/usr/local/lib
CFLAGS = -I /usr/local/include $(DEP) -D_TMHOST_
CFLAGS += -Wall -Wextra -DCRC8
#CFLAGS += -DUSE_STDERR
OBJS = tmhost.o crc8-ccitt.o parse.o parse_format.o \
	command.o

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) -o $(TARGET) $(LDFLAGS)
clean:
	-rm -f $(OBJS) $(TARGET)
