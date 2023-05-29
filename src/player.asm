; player.asm
global _player_load
global _player_free
global _player_move
global _player_render
global _player_update

; redball.asm
extern _redball_spawn

; utils.asm
extern _utils_exit_and_print_sdl_error

; SDL 2
extern _SDL_UpperBlit       ; (SDL_BlitSurface is a macro)
extern _SDL_FreeSurface
extern _SDL_GetKeyboardState
extern _IMG_Load

section .data
    img_path                db "./assets/player.png",0
    speed                   equ 5
    
section .bss
    player_surface          resq 1 
    player_rect             resb 32 
    player_dir              resb 4 
    
section .text

_player_load:
    ; Load image
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

_player_update:
    mov r8,  [rel player_rect + 0]
    mov r9,  [rel player_rect + 4]

    ; We need a dir to be able to move.
    mov ax, [rel player_dir]
    cmp ax, 0
    je update_end
    
    ; Calculate new positon for x
    mov ax, [rel player_dir]
    or  ax, 0b0011
    xor ax, 0b0011
    cmp ax, 0b1000
    je move_left
    cmp ax, 0b0100
    jne x_move_end
    add r8, speed
    jmp x_move_end
    move_left:
    sub r8, speed
    x_move_end:

    ; Calculate new positon for y
    mov ax, [rel player_dir]
    or  ax, 0b1100
    xor ax, 0b1100
    cmp ax, 0b0010
    je move_up
    cmp ax, 0b0001
    jne y_move_end
    add r9, speed
    jmp y_move_end
    move_up:
    sub r9, speed
    y_move_end:

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
    update_end:
    ret

_player_move:
    ; TODO: Refactor _player_move.
    
    ; Fetch key array 
    mov rdi, 0      ; nullptr
    call _SDL_GetKeyboardState

    ; SDL_SCANCODE_RIGHT (79)
    add rax, 79  
    cmp dword [rax], 1
    jne no_redball_r
    mov rdi, [rel player_rect + 0]
    mov rsi, [rel player_rect + 4]
    mov rdx, 0b0100
    call _redball_spawn
    no_redball_r:
    sub rax, 79  

    ; SDL_SCANCODE_LEFT (80)
    add rax, 80  
    cmp dword [rax], 1
    jne no_redball_l
    mov rdi, [rel player_rect + 0]
    mov rsi, [rel player_rect + 4]
    mov rdx, 0b1000
    call _redball_spawn
    no_redball_l:
    sub rax, 80  
    
    ; SDL_SCANCODE_DOWN (81)
    add rax, 81  
    cmp dword [rax], 1
    jne no_redball_d
    mov rdi, [rel player_rect + 0]
    mov rsi, [rel player_rect + 4]
    mov rdx, 0b0001
    call _redball_spawn
    no_redball_d:
    sub rax, 81  

    ; SDL_SCANCODE_UP (82)
    add rax, 82  
    cmp dword [rax], 1
    jne no_redball_u
    mov rdi, [rel player_rect + 0]
    mov rsi, [rel player_rect + 4]
    mov rdx, 0b0010
    call _redball_spawn
    no_redball_u:
    sub rax, 82 

    mov r8, 0
    
    ; SDL_SCANCODE_A (4)
    add rax, 4  ; 0 + 4  = 4
    cmp dword [rax], 1
    jne not_scancode_A
    or r8, 0b1000
    not_scancode_A:

    ; SDL_SCANCODE_D (7)
    add rax, 3  ; 4 + 3  = 7
    cmp dword [rax], 1
    jne not_scancode_B
    or r8, 0b0100
    not_scancode_B:

    ; SDL_SCANCODE_S (22)
    add rax, 15  ; 7 + 15  = 22
    cmp dword [rax], 1
    jne not_scancode_S
    or r8, 0b0001
    not_scancode_S:

    ; SDL_SCANCODE_W (26)
    add rax, 4  ; 22 + 4  = 26 
    cmp dword [rax], 1
    jne not_scancode_W
    or r8, 0b0010
    not_scancode_W:

    mov [rel player_dir], r8d

    ret

error:
    push rbp
    mov rbp, rsp
    call _utils_exit_and_print_sdl_error
