.PHONY: all
all: mini_kernel.img

boot.o: boot.s
	as -c -o boot.o boot.s

kernel.elf: kernel.ld boot.o
	ld -o kernel.elf -T kernel.ld boot.o

mini_kernel.img: kernel.elf
	objcopy -O binary kernel.elf mini_kernel.img

.PHONY: clean
clean:
	@rm -f boot.o
	@rm -f kernel.elf
	@rm -f mini_kernel.img
