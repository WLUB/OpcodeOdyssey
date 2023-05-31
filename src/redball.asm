; redball.asm
global _redball_load
global _redball_free
global _redball_interact
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
    redball_surface     resq 1 
    redball_rect        resb 32 
    redball_dir         resb 1 
    redball_in_air      resb 1

section .text

_redball_load:
    ; Load image
    mov rdi, img_path  ; src
    call _IMG_Load
    mov [rel redball_surface], rax

    ; Check for errors
    test rax, rax                   
    jz error   

    ; Init redball rect
    ; Spawn it outside of the screen
    mov eax, 1000
    mov ebx, 32
    mov [rel redball_rect + 0 ], eax  ;   x
    mov [rel redball_rect + 4 ], eax  ;   y
    mov [rel redball_rect + 8 ], ebx  ;   w
    mov [rel redball_rect + 12], ebx  ;   h
    
    ; Make it available
    mov ch, 1
    mov [rel redball_in_air], ch
    
    ret

_redball_free:
    ; Free redball image
    mov rdi, [rel redball_surface] 
    call _SDL_FreeSurface
    ret

; Inputs: x (32 bit) y (32 bit) direction (8 bit) 
; Output: in air (1/0)
_redball_interact:
    ; Make sure we can only fire one at a time
    ; We don't have any system in place to spawn 
    ; more then one... 
    cmp BYTE [rel redball_in_air], 0
    je redball_catch
    redball_throw:
        mov [rel redball_rect + 0 ], edi  ;   x (input)
        mov [rel redball_rect + 4 ], esi  ;   y (input)

        ; If input direction is zero we
        ; throw the ball down.
        cmp rdx, 0
        jne redball_spawn_valid_dir
        mov dl, 0b00000001          
        redball_spawn_valid_dir:
        
        mov [rel redball_dir], dl   ;   direction (input)

        ; Make the ball unavailable
        mov bl, 0
        mov [rel redball_in_air], bl

        ; Return false
        mov al, 0

        jmp _redball_interact_end

    redball_catch:
        ; edi  ;   x (input)
        ; esi  ;   y (input)

        ; Is the ball inside [-32, 96] of player.x?
        mov r8d, edi
        sub r8d, 32
        cmp dword [rel redball_rect + 0], r8d 
        jl no_intersection

        mov r8d, edi
        add r8d, 96 ; user is 64 we make it larger
        mov r9d, [rel redball_rect + 0]
        add r9d, 32

        cmp r9d, r8d 
        jg no_intersection

        ; Is the ball inside [-20, 84] of player.y?
        mov r8d, esi
        sub r8d, 32
        cmp dword [rel redball_rect + 4], esi 
        jl no_intersection

        mov r8d, esi
        add r8d, 96 ; user is 64 we make it larger
        mov r9d, [rel redball_rect + 4]
        add r9d, 32 

        cmp r9d, r8d 
        jg no_intersection

        ; Move ball 
        mov r8d, 1000
        mov [rel redball_rect + 0 ], r8d  ;   x
        mov [rel redball_rect + 4 ], r8d  ;   y
        
        ; Make the ball available
        mov bl, 1
        mov [rel redball_in_air], bl

        ; Return true
        mov al, 1

        no_intersection:
    _redball_interact_end:
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
    ; If the ball issnt in the air we make it
    ; follow the player.
    cmp BYTE [rel redball_in_air], 1
    jne fly_around
    follow_player:

        ; Set the ball in the hand of the player
        mov r8, [rdi]
        add r8d, 42
        mov [rel redball_rect + 0], r8d

        mov r8, [rdi + 4]
        add r8d, 20
        mov [rel redball_rect + 4], r8d

        jmp update_end

    fly_around:
        mov r8d,  [rel redball_rect + 0]
        mov r9d,  [rel redball_rect + 4]

        ; We need a dir to be able to move.
        mov al, [rel redball_dir]
        cmp al, 0
        je update_end
        
        ; Calculate new positon for x
        mov al, [rel redball_dir]
        or  al, 0b00000011
        xor al, 0b00000011
        cmp al, 0b00001000
        je move_left
        cmp al, 0b00000100
        jne x_move_end
        add r8d, speed
        jmp x_move_end
        move_left:
        sub r8d, speed
        x_move_end:

        ; Calculate new positon for y
        mov al, [rel redball_dir]
        or  al, 0b00001100
        xor al, 0b00001100
        cmp al, 0b00000010
        je move_up
        cmp al, 0b00000001
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
        jl invert_motion 
        cmp r8d, 512   
        jg invert_motion 
        mov [rel redball_rect + 0], r8d
        
        ; Update redball in x-position
        ; Reference point is top-left corner
        ; if 64 < y < 480 - 64 * 2
        cmp r9d, 64   
        jl invert_motion 
        cmp r9d, 352   
        jg invert_motion 
        mov [rel redball_rect + 4], r9d

        jmp update_end
        invert_motion:

        mov al, [rel redball_dir]
        xor al, 0b00001111
        mov [rel redball_dir], al

    update_end:
    ret

error:
    push rbp
    mov rbp, rsp
    call _utils_exit_and_print_sdl_error
