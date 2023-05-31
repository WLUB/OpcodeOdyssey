; main.asm
global _main

; player.asm
extern _player_load
extern _player_free
extern _player_move
extern _player_render
extern _player_update

; redball.asm
extern _redball_load
extern _redball_free
extern _redball_render
extern _redball_update

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
        ; Call renderer
        call render

        ; A small Delay to get ~60 fps 
        ; We don't need to be so precise                            
        mov rdi, 16      
        call _SDL_Delay 

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
        cmp dword [rel event], 0x301    ; SDL_KEYUP       
        je key_search  

        ; Check if the user has used keyboard
        cmp dword [rel event], 0x300    ; SDL_KEYDOWN       
        jne no_keydown  

        key_search: 
            push rbp    
            mov rbp, rsp 
            call _player_move  
            pop rbp
        no_keydown:
    
        jmp main_loop_inner
    main_loop_quit:
        ret  ; Return to _main   

render:  
    push rbp    
    mov rbp, rsp 
    
    ; Render background first
    mov rdi, [rel window_surface]  
    call _background_render

    ; Player update will return 
    ; it's position as a pointer.
    ; We should probably do a 
    ; separate function "get_position"
    call _player_update
    mov rdi, rax 
    call _redball_update

    mov rdi, [rel window_surface]  
    call _player_render

    mov rdi, [rel window_surface]  
    call _redball_render

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
    ; Free all the images
    call _player_free
    call _background_free
    call _redball_free
    pop rbp

    ; Quit SDL
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
    call _background_load
    call _player_load
    call _redball_load

    pop rbp
    ret

error:
    call _utils_exit_and_print_sdl_error
