# 16 BIT REAL MODE
## Simple infinite loop
### Basics
Here we write a basic program to run an infinite loop from the hard disk. 
Points to keep in mind: 
- BIOS is a built-in program that tries to read all readables.
- BIOS only reads 512 bytes i.e. one sector of all the available readables.
- Based on whether it found the magic number (0xaa55) at the end of each readables it declares them as bootable devices. For example the following lines of data is considered bootable as it ends with 0xaa55 in a little endian format(thus 55 aa is read as 0xaa55).
```
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
* 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 55 aa
```
- This above snippet of code does nothing as everything else is a zero

### The loop using the jmp instruction 
The following code is an infinite loop(??).
```asm
jmp $
```
Here `$` is a pointer to current label. Thus is the same as 
```asm
.loop:
  jmp .loop
```
Similarly `$$` points to the start of the program. So to find the number of bytes we've written we can subtract `$$` from `$`. And fill the rest of the bytes to `0`.

```asm
; In total we have 512 bytes
jmp $

; Using the times keyword to repeat something n times
; 512 = ($-$$) + (# of zeros) => (# of zeros) = 512 - ($-$$)
times (512 - ($-$$)) db 0
```

Now since we need the last two bytes to be 0xaa and 0x55 for the BIOS to recognise this as a 
bootable, we only fill `510 - ($-$$)` bytes with `0`s.
```asm
jmp $
times (510 - ($-$$)) db 0
db 0x55
db 0xaa ; little endian format is followed thus 0x55 comes before 0xaa.
```

Since one word equals to two bytes we can use the `dw`(define word) keyword as follows:
```asm
jmp $
times (510 - ($-$$)) db 0
dw 0xaa55
```

### Execution
To execute the code we will use `nasm` and 'qemu'.
- `_nasm_` is an assembler that we will use to convert our assembly code to machine code(binary) and write it down to the readable(floppy disk)
- `_qemu_` is an emulator software we will use to check if the code execution worked.

Assemble the code to a binary
```bash
nasm src/boot.asm -f bin -o build/boot.bin
```

Run qemu
```bash
qemu-system-x86_64 build/boot.bin
```

It is always better to use a makefile for such tasks
```make
ASM=nasm
SRC=src
BUILD=build

assemble:
	$(ASM) $(SRC)/boot.asm -f bin -o $(BUILD)/boot.bin
```
The message `Booting from Hard Disk...` will be displayed on the emulator.

## Print characters
### Interrupts
`Interrupts` are exactly what they mean. 
The CPU controls various processes, but conditionally some events need immediate attention 
thus singnals called as interrupts are sent to the CPU. After which the CPU stops its current 
task and executes spicific task called as interrupt handler.
If CPU is the brain of the computer then Interrupts are the reflex actions.

- We will be using interrupts to print a character onto the screen.
- The `int` intstruction is used to trigger an interrupt.
- To print to screen we will be using the `int 0x10` interrupt specifically.

### Printing one character
Simple steps need to be remembered to print to screen.
- Register `ah` holds the value `0x0e`, this tell the bios to enter tty mode(Some printing mode).
- Register `al` holds the character that has to be printed.
- Trigger the interrupt.

We also add the `[bits 16]` directive tell the assembler that all of these intstructions run in 
16 bit real mode.

```asm
[bits 16]

mov ah, 0x0e ; enter the tty mode for printing onto the screen
mov al, 'A' ; print the character A onto the screen
int 0x10 ; trigger the interrupt to print onto the screen

jmp $ ; run the infinite loop after performing all operations

times (510 - ($-$$)) db 0
dw 0xaa55
```

The character `A` will be displayed after the message `Booting from Hard Disk...`

### Printing strings
Now that we know how to print one character we can print sentences.
To follow a `C language` type format, 
we can define the `main` label where all the other function calls are made, and `jmp $` 
can be seen as a `return 0`.
After defining the `print` function we can write it by using a loop and printing each character
till we meet a null `0` byte. \

**Note**: \
The BIOS actually loads the program into RAM starting at offset `0x7c00` for some reason. \
Hence we will have to offset our entire program by adding the `[org 0x7c00]` directive. \

The final code looks like this:

```asm
[bits 16]
[org 0x7c00]

jmp main

;
; print function
; parameters:
;   input-> bx pointer to the first character
;   output-> null
;

print:

  pusha
  mov ah, 0x0e ; enter the tty mode for printing onto the screen

.loop:

  mov al, [bx] ; print the character onto the screen
  cmp al, 0x0 ; check for null byte
  je .done

  int 0x10 ; trigger the interrupt to print onto the screen
  inc bx ; move to the next byte 
  jmp .loop

.done:

  popa
  ret ; continue to where the function call was made

;
; the main function 
;

main:
  mov bx, message ; move the message to bx register as a paramter to the print function
  call print 
  jmp $ ; run the infinite loop after performing all operations

message: ; the variable only points to the character 'H'
  db "Hello world!", 0

times (510 - ($-$$)) db 0
dw 0xaa55
```

Running this will print "Hello world!" onto the screen.


