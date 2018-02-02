CC=arm-linux-gnueabi-gcc
LD=arm-linux-gnueabi-ld

CFLAGS=-ansi -g -pedantic -Wall -Wextra -march=armv7-a -mfpu=neon -fPIC -mapcs-frame
LDFLAGS=-N -Ttext=0x10000

.PHONY: clean

clean:
		$(RM) *.elf *.o

.SUFFIXES: .s .o .elf

.s.o:
		$(CC) $(CFLAGS) -o $@ -c $^

.o.elf:
		$(LD) $(LDFLAGS) -o $@ $^

kernel.elf: print.o math.o complex.o mandelbrot.o
