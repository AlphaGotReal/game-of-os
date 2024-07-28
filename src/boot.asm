[bits 16]
[org 0x7c00]

KERNEL_LOCATION equ 0x1000

; define the position of the code and data segments with respect to the gdt_begin
; equ is used to define constants
CODE_SEGMENT equ code_descriptor - gdt_begin
DATA_SEGMENT equ data_descriptor - gdt_begin

jmp real_mode_main

;
; print function
; parameters:
;   input-> bx pointer to the first character
;   output-> null
;

rm_print:

  pusha
  mov ah, 0x0e ; enter the tty mode for printing onto the screen

.rm_print_loop:

  mov al, [bx] ; print the character onto the screen
  cmp al, 0x0 ; check for null byte
  je .rm_print_done

  int 0x10 ; trigger the interrupt to print onto the screen
  inc bx ; move to the next byte 
  jmp .rm_print_loop

.rm_print_done:

  popa
  ret ; continue to where the function call was made

;
; the main function 
;

real_mode_main:

  mov [BOOT_DISK], dl

  ; reset the segments variables
  xor ax, ax ; clear ax                         
  mov es, ax 
  mov ds, ax
  mov bp, 0x8000
  mov sp, bp

  ; read more sectors of the disk
  ; specify the following
  ; what disk to read? 
  ; CHS addressing
  ; how many sectors to read
  ; where to load them -> KERNEL_LOCATION
  mov bx, KERNEL_LOCATION ; read to KERNEL_LOCATION
  mov dh, 2

  mov ah, 0x2 ; tells the CPU to read more sectors
  mov al, 1 ; this is the number of sectors to read
  mov ch, 0 ; cylinder number
  mov cl, 2 ; sector number
  mov dh, 0 ; head number
  mov dl, [BOOT_DISK] ; disk number, same as the first one
  int 0x13

  ; enter text mode => clear the screen
  mov ah, 0x0
  mov al, 0x3
  int 0x10

  mov bx, rm_message ; move the message to bx register as a paramter to the print function
  ; call rm_print 

  cli ; clear all the interrupts
  lgdt [gdt_descriptor] ; load the global descriptor table

  ; indirectly changing the last bit of cr0 to 1
  mov eax, cr0
  or eax, 0x1
  mov cr0, eax
 
  jmp CODE_SEGMENT:protected_mode_main
  
  jmp $ ; run the infinite loop after performing all operations

BOOT_DISK: 
  db 0

;
; the global descriptor table 
;

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
  times 3 db 0x0 ; first 24 bits of the base pointer
  db 0b10011010 ; present, priviledge, type, type flags
  db 0b11001111 ; other flags rest 4 bits of the limit
  db 0b0000 ; rest 8 bits of the limit

data_descriptor:
  ; data we have to put together
  
  ; - base pointer: 0b 00000000 00000000 00000000 00000000 (32 bits)
  ; - limit: 0b 1111 1111 1111 1111 1111 (0xfffff, 20 bits)
  ; - present, priviledge, type: 0b1001
  ; - type flags: 0b0010
  ; - other flags: 0b1100

  ; here the values break down and assemble in the following fashion
 
  dw 0xffff ; first 16 bits of the limit
  times 3 db 0x0 ; first 24 bits of the base pointer
  db 0b10010010 ; present, priviledge, type, type flags
  db 0b11001111 ; other flags rest 4 bits of the limit
  db 0b0000 ; rest 8 bits of the limit

gdt_end:

gdt_descriptor:
  ; this will contain the size first then the start of the GDT
  dw gdt_begin - gdt_end - 1 ; size
  dd gdt_begin ; start

rm_message: ; the variable only points to the character 'H'
  db "Hello world!", 0

[bits 32]

VIDEO_MEMORY equ 0xb8000
COLOR_CODE equ 0x60

; color coding
;
; 0 -> black
; 1 -> blue
; 2 -> green
; 3 -> cyan
; 4 -> red
; 5 -> pink
; 6 -> orange
; 7 -> gray
; 8 -> dark gray
; 9 -> light blue
; a -> light green
; b -> light cyan
; c -> light red
; d -> light pink
; e -> light yellow
; f -> white

pm_print:
  pusha
  mov edx, VIDEO_MEMORY

.pm_print_loop:

  mov al, [ebx] ; ebx points to the character we want to print
  cmp al, 0x0
  je .pm_print_done

  mov ah, COLOR_CODE ; printing colors
  ; now ax contains information about what character to print and in what color
  mov [edx], ax ; move the character 
  inc ebx 
  add edx, 2
  jmp .pm_print_loop

.pm_print_done:

  popa 
  ret

protected_mode_main:

  ; initial setup for all the segment registers for data
  mov ax, DATA_SEGMENT
  mov ds, ax
  mov ss, ax
  mov es, ax
  mov fs, ax
  mov gs, ax
  mov ebp, 0x90000 ; 32 bit base pointer
  mov esp, ebp
  
  jmp KERNEL_LOCATION ; make a far jump to kernel location

times (510 - ($-$$)) db 0
dw 0xaa55
