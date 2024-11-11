CC = gcc
CFLAGS = -c -m32
LD = ld
LDFLAGS = -T pci_rom.ld

ASM = as
ASFLAGS = --32
OBJCPY = objcopy
OBJCPY_FLAGS = -v -O binary

OBJS := crt0.o main.o ports.o video.o
ROM_OBJ = rom.elf
ROM_BIN = rom.bin
ROM_SIZE = 65536

all: $(OBJS)
	$(LD) $(LDFLAGS) -o $(ROM_OBJ) $(OBJS)
	$(OBJCPY) $(OBJCPY_FLAGS) $(ROM_OBJ) $(ROM_BIN)

# build_rom $(ROM_BIN) $(ROM_SIZE)

crt0.o: crt0.S
	$(ASM) $(ASFLAGS) -o $@ $< 

%.o: %.c
	$(CC) -o $@ $(CFLAGS) $<

clean:
	rm -rf *.o *.elf *.bin
