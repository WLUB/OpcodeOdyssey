; Created: 2023-05-28 
; Author: Lukas Bergström

; main.asm
global _main

; player.asm
extern _player_load
extern _player_free
extern _player_render
extern _player_move

; background.asm
extern _background_load
extern _background_free
extern _background_render

; window.asm
extern _window_init_sdl
extern _window_create
extern _window_create_surface

; utils.asm
extern _utils_exit_and_print_sdl_error
extern _utils_print

; SDL 2
extern _SDL_Quit
extern _SDL_Delay
extern _SDL_MapRGB
extern _SDL_FillRect
extern _SDL_PollEvent
extern _SDL_DestroyWindow
extern _SDL_UpdateWindowSurface

section .bss
    window_id               resq 1
    window_surface          resq 1
    event                   resb 56   

section .text

_main:
    call init   
    call main_loop                   
    call clean_up
    ret

main_loop:
    main_loop_inner:
        ; Poll for events
        ; Load the address of 'event' into rdi
        mov rdi, event         
        call _SDL_PollEvent

        ; Check if there was an event
        test rax, rax          
        jz main_loop_inner

        ; Check if the user has clicked the close button
        cmp dword [rel event], 0x100    ; SDL_QUIT
        je main_loop_quit

        ; Check if the user has used keyboard
        cmp dword [rel event], 0x300    ; SDL_KEYDOWN       
        jne no_keydown  

        push rbp    
        mov rbp, rsp 
        call _player_move  
        pop rbp

        no_keydown:
    
        ; call render
        call render

        ; A small Delay                               
        mov rdi, 1      
        call _SDL_Delay 

        jmp main_loop_inner
    main_loop_quit:
        ret  ; Return to Main on quit    

render:  
    push rbp    
    mov rbp, rsp 

    mov rdi, [rel window_surface]  
    call _background_render

    mov rdi, [rel window_surface]  
    call _player_render

    ; Redraw the window
    mov rdi, [rel window_id]        
    call _SDL_UpdateWindowSurface ; 0 on success 
    
    ; Check for errors
    test rax, rax                   
    jnz error
 
    ; Clean screen
    mov rdi, [rel window_surface]   ; window_surface
    add rdi, 32                     ; window_surface->format (jump 32 bit)
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
    
    call _player_free
    call _background_free

    pop rbp

    ;  Quit SDL
    mov rdi, [rel window_id]         
    call _SDL_DestroyWindow 
    call _SDL_Quit   
    ret


init:
    push rbp    
    mov rbp, rsp 

    ; Init SDL 
    call _window_init_sdl

    ; Check for errors
    test rax, rax                   
    jnz error    

    ; Create a window
    call _window_create
    mov [rel window_id], rax

    ; Check for errors
    test rax, rax                   
    jz error

    ; Create a window surface
    mov rdi, [rel window_id]            
    call _window_create_surface
    mov [rel window_surface], rax

    ; Check for errors
    test rax, rax                  
    jz error
    
    ; Init objects...
    call _player_load
    call _background_load

    pop rbp
    ret

error:
    call _utils_exit_and_print_sdl_error
