; main.asm
;
; Created: 2023-05-28 
; Author: Lukas Bergström
;
; A test of creating a simple game  
; in x86 asm for MacOS
; -------------------------------------------------
; Note to self;
;   * Find header here /Library/Frameworks/SDL2.framework/Headers
;   *  System V AMD64 calling convention (https://en.wikipedia.org/wiki/X86_calling_conventions#System_V_AMD64_ABI)
;       - rdi, rsi, rdx, rcx, r8 and r9. (order)
;-------------------------------------------------
;
section .data
    ; Window variables
    winname                 db "ASM!",0
    width                   equ 640
    height                  equ 480
    
    ; Player
    player_img_path         db "./assets/player.bmp",0
    img_mode                db "r",0

    ; Debug messages
    exit_message            db "Goodbye!",0x0A,0
    init_complete           db "Init complete",0x0A,0
    sdl_error               db "SDL Error occured: %s",0x0A,0

section .bss
    ; Window settings
    winid                   resq 1
    winSurface              resq 1
    event                   resb 56   

    ; Player vars.
    player_img              resq 1 
    player_rect             resw 4   

section .text
    global _main

    ; Utils
    extern _printf

    ; SDL 2
    extern _SDL_Init
    extern _SDL_Quit
    extern _SDL_Delay
    extern _SDL_MapRGB
    extern _SDL_FillRect
    extern _SDL_GetError
    extern _SDL_PollEvent
    extern _SDL_RWFromFile
    extern _SDL_LoadBMP_RW
    extern _SDL_UpperBlit ; _SDL_BlitSurface <- macro...
    extern _SDL_FreeSurface
    extern _SDL_CreateWindow
    extern _SDL_DestroyWindow
    extern _SDL_GetKeyboardState
    extern _SDL_GetWindowSurface
    extern _SDL_UpdateWindowSurface

_main:
    call init_sdl                   ; Initialize the SDL library
    call create_window              ; Create a window and renderer
    call load_player

    lea rdx, [rel init_complete]    ; Debug
    call print   
    
    call main_loop                  ; Enter the Main loop 
    call clean_up

    lea rdx, [rel exit_message]     ; Debug
    call print   
    
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
    je check_key_down  
    no_key_down:

    ; Go to render part, a bit unnecessary but
    ; the code becomes a bit more frendly
    jmp main_loop_render                       
    main_loop_render_done: 
                                    
    mov rdi, 1      ; A small Delay
    call _SDL_Delay 

    jmp main_loop

    check_key_down:
        ; Fetch key array 
        mov rdi, 0      ; nullptr
        call _SDL_GetKeyboardState
        
        add rax, 4  ; SDL_SCANCODE_A = 4
        cmp dword [rax], 1
        jne not_scancode_A

        ; Move to right
        mov rdi, [rel player_rect] ; x
        sub rdi, 5
        mov [rel player_rect], rdi

        not_scancode_A:
        add rax, 3  ; SDL_SCANCODE_D = 7
        cmp dword [rax], 1
        jne not_scancode_B

        ; Move to right
        mov rdi, [rel player_rect] ; x
        add rdi, 5
        mov [rel player_rect], rdi

        not_scancode_B:
        add rax, 15  ; SDL_SCANCODE_S = 22
        cmp dword [rax], 1
        jne not_scancode_S

        ; Move to right
        mov rdi, [rel player_rect + 4] ; y
        add rdi, 5
        mov [rel player_rect + 4], rdi

        not_scancode_S:
        add rax, 4  ; SDL_SCANCODE_W = 26
        cmp dword [rax], 1
        jne no_key_down

        ; Move to right
        mov rdi, [rel player_rect + 4] ; y
        sub rdi, 5
        mov [rel player_rect + 4], rdi

        jmp no_key_down

    main_loop_render:  
        mov rdi, [rel player_img]   ; src
        mov rsi, 0                  ; rect
        mov rdx, [rel winSurface]   ; dst
        mov rcx, player_rect        ; dstrect
        call _SDL_UpperBlit         ; error code?? 0 on success? 

        ; Check for errors
        test rax, rax                   
        jnz error

        ; Redraw the window
        mov rdi, [rel winid]        
        call _SDL_UpdateWindowSurface ; 0 on success 
        
        ; Check for errors
        test rax, rax                   
        jnz error

        ; Clean screen
        mov rdi, [rel winSurface]   ; window_surface
        add rdi, 32                 ; window_surface->format (jump 32 bit)
                                    ; Feels like i should be able to do
                                    ; [rel winSurface + 4]

        mov rsi, 0
        mov rdx, 0
        mov rcx, 0
        call _SDL_MapRGB    ; Returns a pixel value (no errors?)

        mov rdi, [rel winSurface]
        mov rsi, 0
        mov rdx, rax
        call _SDL_FillRect  ; 0 on success

        ; Check for errors
        test rax, rax                   
        jnz error


        jmp main_loop_render_done

    main_loop_quit:
        ; Return to Main on quit                
        ret                         
    
clean_up:
    ; Free player image
    mov rdi, [rel player_img] 
    call _SDL_FreeSurface

    ; Quit SDL
    mov rdi, [rel winid]         
    call _SDL_DestroyWindow 
    call _SDL_Quit           
    ret

load_player:
    ; Loading BPM image
    mov rdi, player_img_path  ; src
    mov rsi, img_mode         ; mode 
    call _SDL_RWFromFile

    ; Check for errors
    test rax, rax                   
    jz error   

    mov rdi, rax  ; src
    mov rsi, 1                      ; freesrc
    call _SDL_LoadBMP_RW
    mov [rel player_img], rax

    ; Check for errors
    test rax, rax                   
    jz error   

    ; Init player rect
    mov rax, 40
    mov rbx, 64
    mov [rel player_rect],     rax  ;   x
    mov [rel player_rect+4],   rax  ;   y
    mov [rel player_rect+8],   rbx  ;   w
    mov [rel player_rect+12],  rbx  ;   h

    ret

init_sdl:
    ; Initialize the SDL library
    mov rdi, 0x0000F231 ; SDL_INIT_EVERYTHING
    call _SDL_Init      ; Return 0 on success

    ; Check for errors
    test rax, rax                   
    jnz error           

    ret

create_window:
    ; Create a window
    mov rdi, winname    ; title
    mov esi, 0          ; x
    mov edx, 0          ; y
    mov ecx, width      ; w
    mov r8d, height     ; h
    mov r9d, 0          ; flags   SDL_WINDOW_SHOWN | SDL_WINDOW_OPENGL = 4 | 2 = 6
    call _SDL_CreateWindow

    mov [rel winid], rax

    ; Check for errors
    test rax, rax                   
    jz error

    ; Create a window surface
    mov rdi, [rel winid]            
    call _SDL_GetWindowSurface
    mov [rel winSurface], rax

    ; Check for errors
    test rax, rax                  
    jz error
    
    ret

print: 
    ; rdx will contain the address of the string to be printed
    mov rdi, rdx                 
    xor rax, rax ; Set 0 inputs
    call _printf
    ret

error: 
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
