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
