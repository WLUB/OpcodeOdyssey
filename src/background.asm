; Created: 2023-05-29
; Author: Lukas Bergström

; background.asm
global _background_load
global _background_free
global _background_render

; utils.asm
extern _utils_exit_and_print_sdl_error

; SDL 2
extern _SDL_UpperBlit       ; (SDL_BlitSurface is a macro)
extern _SDL_FreeSurface
extern _SDL_GetKeyboardState
extern _IMG_Load

section .data
    img_path                    db "./assets/background.png",0

section .bss
    background_surface          resq 1 
    background_rect             resb 32   

section .text

_background_load:
    ; Loading images
    mov rdi, img_path  ; src
    call _IMG_Load
    mov [rel background_surface], rax

    ; Check for errors
    test rax, rax                   
    jz error   

    ; Init background rect
    mov rax, 0
    mov rbx, 640
    mov rcx, 480
    mov [rel background_rect + 0 ], rax  ;   x
    mov [rel background_rect + 4 ], rax  ;   y
    mov [rel background_rect + 8 ], rbx  ;   w
    mov [rel background_rect + 12], rcx  ;   h

    ret

_background_free:
    ; Free background image
    mov rdi, [rel background_surface] 
    call _SDL_FreeSurface
    ret

_background_render:
    mov rdx, rdi                        ; dst (input)
    mov rdi, [rel background_surface]   ; src
    mov rsi, 0                          ; rect
    mov rcx, background_rect            ; dstrect
    call _SDL_UpperBlit                 ; error code?? 0 on success? 
    
    ; Check for errors
    test rax, rax                   
    jnz error

    ret

error:
    push rbp
    mov rbp, rsp
    call _utils_exit_and_print_sdl_error
