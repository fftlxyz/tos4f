CC      := gcc -g -pipe -nostdinc -Iinc 
AS      := as -gstabs
AR      := ar
LD      := ld
OBJCOPY := objcopy
OBJDUMP := objdump
NM      := nm
LDFLAGS := -m elf_i386
CPP     := cpp -nostdinc -Iinc

all: image

boot_objs := boot/boot.o boot/bootmain.o
kern_objs := kern/kern.o


boot/boot.o: boot/boot.S
	$(CC) -Os -c -o $@ $<

boot/bootmain.o: boot/bootmain.c
	$(CC) -Os -c -o $@ $<

kern/kern.o: kern/kern.S
	$(CC) -c -o $@ $<

boot/boot: $(boot_objs)
	$(LD) $(LDFLAGS) -N -e start -Ttext 0x7C00 -o $@.out $^
	$(OBJDUMP) -S $@.out >$@.asm
	$(OBJCOPY) -S -O binary $@.out $@
	perl boot/sign.pl $@

kern/kern: $(kern_objs)
	$(LD) $(LDFLAGS) -N -e start -Ttext 0x0000 -o $@.out $^
	$(OBJDUMP) -S $@.out >$@.asm
	$(OBJCOPY) -S -O binary $@.out $@

image: boot/boot kern/kern
	dd if=/dev/zero of=./bochs.img~ count=10000 2>/dev/null
	dd if=./boot/boot of=./bochs.img~ conv=notrunc 2>/dev/null
	dd if=./kern/kern of=./bochs.img~ bs=512 seek=1 conv=notrunc  2>/dev/null
	mv ./bochs.img~ ./bochs.img

# For deleting the build
clean:
	rm -f boot/boot
	rm -f boot/*.o boot/*.out boot/*.asm
	rm -f kern/kern
	rm -f kern/*.o kern/*.out kern/*.asm
	rm bochs.img  bochs.log -f

.PHONY:	clean
