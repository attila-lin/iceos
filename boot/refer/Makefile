NASM=nasm
QEMU=qemu

all: first.flp

.SUFFIXES:

.SUFFIXES: .asm

.PHONY: clean run

first.bin: first.asm
	$(NASM) -o $@ -f bin $<

first.flp: first.bin
	dd status=noxfer conv=notrunc if=$< of=$@

run: first.flp
	$(QEMU) -fda $<

clean:
	rm -f *.bin *.img