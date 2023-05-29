; Created: 2023-05-29
; Author: Lukas Bergström

; utils.asm
global _print
global _exit_and_print_sdl_error

; std
extern _printf

; SDL 2
extern _SDL_Quit
extern _SDL_Delay
extern _SDL_GetError

section .data
    sdl_error   db "SDL Error occured: %s",0x0A,0

section .text

_print: 
    ; rdx will contain the address of the string to be printed
    mov rdi, rdx                 
    xor rax, rax ; Set 0 inputs
    call _printf
    ret

_exit_and_print_sdl_error: 
    ; Get error message from SDL and print it
    ; rsi will contain the address of the format string
    call _SDL_GetError          
    mov rsi, rax                
    lea rdi, [rel sdl_error]
    mov rax, 1  ; Set 1 input
    call _printf
    xor rax, rax

    mov rdi, 1000       ; Delay 1 sec and quit SDL
    call _SDL_Delay     ; Delay might be a bit unnecessary...
    call _SDL_Quit

    ; Exit the program
    mov eax, 0x2000001  ; System call number for exit
    mov edi, 1          ; Exit status 1 
    syscall             ; Invoke the system call
