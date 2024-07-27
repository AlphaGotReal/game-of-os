ASM=nasm
SRC=src
BUILD=build

assemble:
	$(ASM) $(SRC)/boot.asm -f bin -o $(BUILD)/boot.bin


