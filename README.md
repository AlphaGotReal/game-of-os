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
Here `$` is a pointer to current label. Its is the same as 
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
db 0xaa ; little endian format is followed => 0x55 comes before 0xaa.
```

Since one word equals to two bytes we can use the `dw`(define word) keyword.
```asm
jmp $
times (510 - ($-$$)) db 0
dw 0xaa55
```

### Execution
To execute the code we will use `nasm` and `qemu`.
- `nasm` is an assembler that we will use to convert our assembly code to machine code(binary) and write it down to the readable(floppy disk)
- `qemu` is an emulator software we will use to check if the code execution worked.

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
**Interrupts** are exactly what they mean. 
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

# 32 BIT MODE
## Global Descriptor Table(GDT)
`GDT` is the convention used to define the segments and privilages for each segment in
the RAM. Here we use `Descriptors` to describe the properties of each segment we want. For this 
example we will use the Flat-Memory-Model to address the memory(popular ones being segmentation
and paging models). \

To define a segment we set the following properties:
- **Base Pointer(loc)**: The starting address of the segment.
- **Limit(size)**: The size of the segment starting from the offset.
- **Present**: This is a single bit that tells us whether the segment is being used. 
- **Priviledge**: This is a two bit that defines the proority of the segment. `00` being the most powerful.
- **Type(T)**: This single bit tells us whether the segment is begin used for code or data or free space or whatever. `1` corresponds to code or data segment. 
- **Type Flags(Tf)**: A 4 bit telling us the following:
  - **Tf & 0b1000**: This bit is set when the segment is being used as a code segment.
  - **Tf & 0b100**: 
    - For Code: Setting this bit allows lower Priviledged segments to access this.
    - For Data: This defines the direction of growth. `0` -> expand up segment.
  - **Tf & 0b10**: 
    - For Code: Whether its readable?
    - For Data: Whether its writable?
  - **Tf & 0b1**: Whether managed by the CPU?
- **Other Flags(Of)**: 
  - **Of & 0b1000**: 1, if set, this multiplies our limit by 4 K (i.e. 16*16*16), so our 0xffff would become 0xffff000 (i.e. shift 3 hex digits to the left), allowing our segment to span 4 Gb of memory.
  - **Of & 0b100**: Whether this segment using 32 bit memory? 32 bits moving in parallel in the bus architecture.
  - **Of & 0b10**: Whether this segment using 64 bit memory? 64 bits moving in parallel in the bus architecture.
  - **Of & 0b10**: Some AVL???

To understand this better look at the values of the Descriptors for code segment(example) and
understand why the values were set.

### Code Segment Descriptor

```
Base Pointer: 0x0000 -> if you want to start the segment at 0.
Limit: 0xfffff -> 20 bits, end of the segment from offet.
Present: 0b1 -> we are using the segment, hence 1.
Priviledge: 0b00 -> set it to the highest proority.
Type: 0b1 -> This is a code segment hence 1.
Type Flags: 0b1010 
Other Flags: 0b1100 
```

### The Table

Now that we know the values the descriptors we can define the GDT in assembly. \
A really weird convention for defining the GDT in assembly is used.\

- First, we define the null descriptor, this is just 8 bytes of zeros. This padding is done for no reason.
- Then we define the code and data segments with the values we got earlier.

```asm
gdt_begin:

null_descriptor:
  ; this is just a padding added
  times 8 db 0 

code_descriptor:
  ; data we have to put together
  
  ; - base pointer: 0b 00000000 00000000 00000000 00000000 (32 bits)
  ; - limit: 0b 1111 1111 1111 1111 1111 (0xfffff, 20 bits)
  ; - present, priviledge, type: 0b1001
  ; - type flags: 0b1010
  ; - other flags: 0b1100

  ; here the values break down and assemble in the following fashion
  
  dw 0xffff ; first 16 bits of the limit
  times 3 db 0 ; first 24 bits of the base pointer
  db 0b1001 ; present, priviledge, type
  db 0b1010 ; type flags
  db 0b1100 ; other flags
  db 0xf ; rest 4 bits of the limit
  times 1 db 0 ; rest 8 bits of the limit

data_descriptor:
  ; data we have to put together
  
  ; - base pointer: 0b 00000000 00000000 00000000 00000000 (32 bits)
  ; - limit: 0b 1111 1111 1111 1111 1111 (0xfffff, 20 bits)
  ; - present, priviledge, type: 0b1001
  ; - type flags: 0b0010
  ; - other flags: 0b1100

  ; here the values break down and assemble in the following fashion
  
  dw 0xffff ; first 16 bits of the limit
  times 3 db 0 ; first 24 bits of the base pointer
  db 0b1001 ; present, priviledge, type
  db 0b0010 ; type flags
  db 0b1100 ; other flags
  db 0xf ; rest 4 bits of the limit
  times 1 db 0 ; rest 8 bits of the limit

gdt_end:
```

Finally we can define the descriptor with labels

```asm
gdt_descriptor:
  ; this will contain the size first then the start of the GDT
  dw gdt_begin - gdt_end - 1 ; size
  dd gdt_begin ; start
```

```asm
; define the position of the code and data segments with respect to the gdt_begin
; equ is used to define constants
CODE_SEGMENT equ code_descriptor - gdt_begin
DATA_SEGMENT equ data_descriptor - gdt_begin
```

### Entering 32 bit protected mode
The first thing we have to do is disable interrupts using the cli (clear interrupt)
instruction, which means the CPU will simply ignore any future interrupts that may
happen, at least until interrupts are later enabled. \
Then we tell the CPU about the GDT by running the `lgdt`(load GDT) command. \
To make the switch to protected mode we set the last bit of the control register to 1.

```asm
cli ; clear all the interrrupts

lgdt [gdt_descriptor]

; indirectly changing the last bit of cr0 to 1
mov eax, cr0 
or eax, 0x1
mov cr0, eax
```

Finally we can jump to 32 bit protected mode by performing a far jump.

```asm
jmp CODE_SEGMENT:protected_mode_main
.
.
.
.
protected_mode_main:
  jpm $ ; infinite loop at the start of the main function in protected mode
```

