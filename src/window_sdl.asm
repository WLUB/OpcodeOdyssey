; Created: 2023-05-29
; Author: Lukas Bergström

; window_sdl.asm
global _init_sdl
global _create_window
global _create_window_surface

; SDL2
extern _SDL_Init
extern _SDL_CreateWindow
extern _SDL_GetWindowSurface

section .data
    window_title            db "Opcode Odyssey",0
    width                   equ 640
    height                  equ 480

section .text

_init_sdl:
    ; Initialize the SDL library
    mov rdi, 0x0000F231 ; SDL_INIT_EVERYTHING
    call _SDL_Init      ; Return 0 on success
    ret

_create_window:
    ; Create a window
    mov rdi, window_title   ; title
    mov esi, 0              ; x
    mov edx, 0              ; y
    mov ecx, width          ; w
    mov r8d, height         ; h
    mov r9d, 0              ; flags 
    call _SDL_CreateWindow  ; 0 on error

    ret

_create_window_surface:
    ; Create a window surface
    call _SDL_GetWindowSurface

    ret
