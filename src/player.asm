; Created: 2023-05-29
; Author: Lukas Bergström

; player.asm
global _load_player
global _free_player
global _render_player
global _move_player

; utils.asm
extern _exit_and_print_sdl_error

; SDL 2
extern _SDL_UpperBlit       ; (SDL_BlitSurface is a macro)
extern _SDL_RWFromFile
extern _SDL_LoadBMP_RW 
extern _SDL_FreeSurface
extern _SDL_GetKeyboardState

section .data
    img_path                db "./assets/player.bmp",0
    img_mode                db "r",0

section .bss
    ; Player variables
    player_img              resq 1 
    player_rect             resw 4   

section .text

_load_player:
    ; Loading BPM image
    mov rdi, img_path  ; src
    mov rsi, img_mode  ; mode 
    call _SDL_RWFromFile

    ; Check for errors
    test rax, rax                   
    jz error   

    mov rdi, rax  ; src
    mov rsi, 1    ; freesrc
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

_free_player:
    ; Free player image
    mov rdi, [rel player_img] 
    call _SDL_FreeSurface

_render_player:
    mov rdx, rdi                ; dst (input)
    mov rdi, [rel player_img]   ; src
    mov rsi, 0                  ; rect
    mov rcx, player_rect        ; dstrect
    call _SDL_UpperBlit         ; error code?? 0 on success? 

    
    ret

_move_player:

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
    
    ; Update player position
    mov [rel player_rect + 0], r8
    mov [rel player_rect + 4], r9

    ret

error:
    call _exit_and_print_sdl_error
