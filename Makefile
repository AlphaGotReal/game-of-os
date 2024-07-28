ASM=nasm
SRC=src
BUILD=build
GCC_CROSS_COMPILER=i386-elf-gcc
GCC_CROSS_LINKER=i386-elf-ld

assemble:
	$(ASM) $(SRC)/boot.asm -f bin -o $(BUILD)/boot.bin
	$(ASM) $(SRC)/kernel_entry.asm -f elf -o $(BUILD)/kernel_entry.o
	$(GCC_CROSS_COMPILER) -ffreestanding -m32 -g -c $(SRC)/kernel.c -o $(BUILD)/kernel.o
	$(ASM) $(SRC)/zeroes.asm -f bin -o $(BUILD)/zeroes.bin
	$(GCC_CROSS_LINKER) -o $(BUILD)/full_kernel.bin -Ttext 0x1000 $(BUILD)/kernel_entry.o $(BUILD)/kernel.o --oformat binary
	cat $(BUILD)/boot.bin $(BUILD)/full_kernel.bin $(BUILD)/zeroes.bin  > $(BUILD)/OS.bin

