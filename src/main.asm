; Created: 2023-05-28 
; Author: Lukas Bergström

; main.asm
global _main

; player.asm
extern _load_player
extern _free_player
extern _render_player
extern _move_player

; window_sdl.asm
extern _init_sdl
extern _create_window
extern _create_window_surface

; utils.asm
extern _exit_and_print_sdl_error
extern _print

; SDL 2
extern _SDL_Quit
extern _SDL_Delay
extern _SDL_MapRGB
extern _SDL_FillRect
extern _SDL_PollEvent
extern _SDL_DestroyWindow
extern _SDL_UpdateWindowSurface

section .data
    exit_message            db "Goodbye!",0x0A,0
    init_complete           db "Init complete",0x0A,0

section .bss
    window_id               resq 1
    window_surface          resq 1
    event                   resb 56   

section .text
 
_main:
    call init                   
    call _load_player
    
    ; Debug
    lea rdx, [rel init_complete]    
    call _print   
    
    call main_loop                   
    call clean_up

    ; Debug
    lea rdx, [rel exit_message]     
    call _print   
    
    ret

main_loop:
    ; Poll for events
    mov rdi, event         ; Load the address of 'event' into rdi
    call _SDL_PollEvent

    ; Check if there was an event
    test rax, rax          
    jz main_loop

    ; Check if the user has clicked the close button
    cmp dword [rel event], 0x100    ; SDL_QUIT
    je main_loop_quit

    ; Check if the user has used keyboard
    cmp dword [rel event], 0x300    ; SDL_KEYDOWN       
    jne no_keydown  
    call _move_player
    no_keydown:

    call render

    ; A small Delay                               
    mov rdi, 1      
    call _SDL_Delay 

    jmp main_loop
    main_loop_quit:
        ret  ; Return to Main on quit    

render:  
    push rbp     ; Save the previous base pointer
    mov rbp, rsp ; Set the base pointer to the current stack pointer

    mov rdi, [rel window_surface]  
    call _render_player

    ; Check for errors
    test rax, rax                   
    jnz error

    ; Redraw the window
    mov rdi, [rel window_id]        
    call _SDL_UpdateWindowSurface ; 0 on success 
    
    ; Check for errors
    test rax, rax                   
    jnz error

    ; Clean screen
    mov rdi, [rel window_surface]   ; window_surface
    add rdi, 32                 ; window_surface->format (jump 32 bit)
                                ; Feels like i should be able to do
                                ; [rel window_surface + 4]

    mov rsi, 0
    mov rdx, 0
    mov rcx, 0
    call _SDL_MapRGB    ; Returns a pixel value (no errors?)

    mov rdi, [rel window_surface]
    mov rsi, 0
    mov rdx, rax
    call _SDL_FillRect  ; 0 on success

    ; Check for errors
    test rax, rax                   
    jnz error

    pop rbp
    ret

clean_up:

    push rbp     
    mov rbp, rsp 
    call _free_player
    pop rbp               

    ; Quit SDL
    mov rdi, [rel window_id]         
    call _SDL_DestroyWindow 
    call _SDL_Quit   

    ret


init:
    push rbp     ; Save the previous base pointer
    mov rbp, rsp ; Set the base pointer to the current stack pointer

    ; Init SDL 
    call _init_sdl

    ; Check for errors
    test rax, rax                   
    jnz error    

    ; Create a window
    call _create_window
    mov [rel window_id], rax

    ; Check for errors
    test rax, rax                   
    jz error

    ; Create a window surface
    mov rdi, [rel window_id]            
    call _create_window_surface
    mov [rel window_surface], rax

    ; Check for errors
    test rax, rax                  
    jz error
    
    pop rbp
    ret

error:
    call _exit_and_print_sdl_error
