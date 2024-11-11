CC = gcc
CFLAGS = -Wall -O2 -march = i686 -mcpu = i686 -c
LD = gcc
LDFLAGS =

all: build_rom.o
	$(LD) $(LDFLAGS) -o build_rom build_rom.o

%.o: %.c
	$(CC) $(CFLAGS) -o $@ $<

clean: rm -rf build_rom *.o