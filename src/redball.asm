; Created: 2023-05-29
; Author: Lukas Bergström

; redball.asm
global _redball_load
global _redball_free
global _redball_spawn
global _redball_render
global _redball_update

; utils.asm
extern _utils_exit_and_print_sdl_error

; SDL 2
extern _SDL_UpperBlit       ; (SDL_BlitSurface is a macro)
extern _SDL_FreeSurface
extern _SDL_GetKeyboardState
extern _IMG_Load

section .data
    img_path            db "./assets/redball.png",0
    speed               equ 10

section .bss
    redball_surface    resq 1 
    redball_rect       resb 32 
    redball_dir        resb 4 
    redball_available  resb 1

section .text

_redball_load:
    ; Loading images
    mov rdi, img_path  ; src
    call _IMG_Load
    mov [rel redball_surface], rax

    ; Check for errors
    test rax, rax                   
    jz error   

    ; Init redball rect
    ; Spawn it outside of the screen
    mov rax, 1000
    mov rbx, 32
    mov [rel redball_rect + 0 ], rax  ;   x
    mov [rel redball_rect + 4 ], rax  ;   y
    mov [rel redball_rect + 8 ], rbx  ;   w
    mov [rel redball_rect + 12], rbx  ;   h
    
    mov ch, 1
    mov [rel redball_available], ch
    
    ret

_redball_free:
    ; Free redball image
    mov rdi, [rel redball_surface] 
    call _SDL_FreeSurface
    ret

_redball_spawn:

    ; Make sure we can only fire one at a time
    cmp BYTE [rel redball_available], 1
    jne redball_spawn_end

    mov [rel redball_rect + 0 ], edi  ;   x (input)
    mov [rel redball_rect + 4 ], esi  ;   y (input)
    mov [rel redball_dir], edx        ;   direction (input)

    mov bh, 0
    mov [rel redball_available], bh

    redball_spawn_end:
    ret

_redball_render:
    mov rdx, rdi                    ; dst (input)
    mov rdi, [rel redball_surface]  ; src
    mov rsi, 0                      ; rect
    mov rcx, redball_rect           ; dstrect
    call _SDL_UpperBlit             ; error code?? 0 on success? 
    
    ; Check for errors
    test rax, rax                   
    jnz error

    ret


_redball_update:
    mov r8,  [rel redball_rect + 0]
    mov r9,  [rel redball_rect + 4]

    ; Controll that we are moving
    mov ax, [rel redball_dir]
    cmp ax, 0
    je update_end
    
    ; Calculate new positon for x
    mov ax, [rel redball_dir]
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
    mov ax, [rel redball_dir]
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

    ; Update redball in x-position
    ; Reference point is top-left corner
    ; if 64 < x < 640 - 64 * 2
    cmp r8d, 64   
    jl destory 
    cmp r8d, 512   
    jg destory 
    mov [rel redball_rect + 0], r8d
    

    ; Update redball in x-position
    ; Reference point is top-left corner
    ; if 64 < y < 480 - 64 * 2
    cmp r9d, 64   
    jl destory 
    cmp r9d, 352   
    jg destory 
    mov [rel redball_rect + 4], r9d

    jmp update_end

    destory:
    ; We do not destory it, we move it...
    mov r8, 1000
    mov [rel redball_rect + 0], r8d
    mov ah, 1
    mov [rel redball_available], ah

    update_end:
    ret

error:
    push rbp
    mov rbp, rsp
    call _utils_exit_and_print_sdl_error
