[bits 16]

jmp main

print:
mov ah, 0x0e ; enter the tty mode for printing onto the screen
mov al, 'A' ; print the character A onto the screen
int 0x10 ; trigger the interrupt to print onto the screen

main:
  jmp $ ; run the infinite loop after performing all operations

times (510 - ($-$$)) db 0
dw 0xaa55
