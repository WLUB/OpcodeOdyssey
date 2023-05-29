; Created: 2023-05-29
; Author: Lukas Bergström

; player.asm
global _player_load
global _player_free
global _player_render
global _player_move

; utils.asm
extern _utils_exit_and_print_sdl_error

; SDL 2
extern _SDL_UpperBlit       ; (SDL_BlitSurface is a macro)
extern _SDL_FreeSurface
extern _SDL_GetKeyboardState
extern _IMG_Load

section .data
    img_path                db "./assets/player.png",0

section .bss
    player_surface          resq 1 
    player_rect             resb 32   

section .text

_player_load:
    ; Loading images
    mov rdi, img_path  ; src
    call _IMG_Load
    mov [rel player_surface], rax

    ; Check for errors
    test rax, rax                   
    jz error   

    ; Init player rect
    mov rax, 100
    mov rbx, 64
    mov [rel player_rect + 0 ], rax  ;   x
    mov [rel player_rect + 4 ], rax  ;   y
    mov [rel player_rect + 8 ], rbx  ;   w
    mov [rel player_rect + 12], rbx  ;   h

    ret

_player_free:
    ; Free player image
    mov rdi, [rel player_surface] 
    call _SDL_FreeSurface
    ret

_player_render:
    mov rdx, rdi                    ; dst (input)
    mov rdi, [rel player_surface]   ; src
    mov rsi, 0                      ; rect
    mov rcx, player_rect            ; dstrect
    call _SDL_UpperBlit             ; error code?? 0 on success? 
    
    ; Check for errors
    test rax, rax                   
    jnz error

    ret

_player_move:

    mov r8,  [rel player_rect + 0]
    mov r9,  [rel player_rect + 4]
    mov rax, 0

    ; Fetch key array 
    mov rdi, 0      ; nullptr
    call _SDL_GetKeyboardState

    ; SDL_SCANCODE_A (4)
    add rax, 4  ; 0 + 4  = 4
    cmp dword [rax], 1
    jne not_scancode_A
    sub r8, 5
    not_scancode_A:

    ; SDL_SCANCODE_D (7)
    add rax, 3  ; 4 + 3  = 7
    cmp dword [rax], 1
    jne not_scancode_B
    add r8, 5
    not_scancode_B:

    ; SDL_SCANCODE_S (22)
    add rax, 15  ; 7 + 15  = 22
    cmp dword [rax], 1
    jne not_scancode_S
    add r9, 5
    not_scancode_S:

    ; SDL_SCANCODE_W (26)
    add rax, 4  ; 22 + 4  = 26 
    cmp dword [rax], 1
    jne not_scancode_W
    sub r9, 5
    not_scancode_W:

    ; Update player in x-position
    ; Reference point is top-left corner
    ; if 64 < x < 640 - 64 * 2
    cmp r8d, 64   
    jl no_x_move 
    cmp r8d, 512   
    jg no_x_move 
    mov [rel player_rect + 0], r8
    no_x_move:

    ; Update player in x-position
    ; Reference point is top-left corner
    ; if 64 < y < 480 - 64 * 2
    cmp r9d, 64   
    jl no_y_move 
    cmp r9d, 352   
    jg no_y_move 
    mov [rel player_rect + 4], r9
    no_y_move:

    ret

error:
    push rbp
    mov rbp, rsp
    call _utils_exit_and_print_sdl_error
