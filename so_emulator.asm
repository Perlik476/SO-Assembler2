global so_emul

section .bss

A: resb 1
D: resb 1
X: resb 1
Y: resb 1
PC: resb 1
unused: resb 1
C: resb 1
Z: resb 1

section .text

arg_pointer:
    cmp r11, 4
    jne check_Y
    mov r11b, [rel X]
    lea r11, [rsi + r11]
    ret
check_Y:
    cmp r11, 5
    jne check_XD
    mov r11b, [rel Y]
    lea r11, [rsi + r11]
    ret
check_XD:
    cmp r11, 6
    jne check_YD
    mov r11b, [rel X]
    add r11b, [rel D]
    lea r11, [rsi + r11]
    ret
check_YD:
    mov r11b, [rel Y]
    add r11b, [rel D]
    lea r11, [rsi + r11]
    ret

arg_pointer_arg1_g0:
    call arg_pointer
    jmp arg_pointer_arg1_back_g0

arg_pointer_arg2_g0:
    call arg_pointer
    jmp arg_pointer_arg2_back_g0

arg_pointer_arg1_g1:
    call arg_pointer
    jmp arg_pointer_arg1_back_g1
    
; rdi - code
; rsi - data
; [rsp] - steps
; [rsp + 8] - core
; r8-r11 - A, D, X, Y
; rdx - PC
so_emul:
        test rsp, rsp
        push rcx ; core - [rsp + 8]
        push rdx ; steps - [rsp]

        pushf

        mov rcx, rdx
        mov rdx, [rel PC]

        cmp rcx, 0
        je end
main_loop:
        xor rax, rax
        mov ax, [rdi + 2 * rdx]

        xor r8, r8
        xor r9, r9

        cmp ax, 0x4000
        jl group0
        sub ax, 0x4000
        cmp ax, 0x4000
        jl group1

group0:
        mov r10b, al

        ; r8 - arg1, r9 - arg2
        shr rax, 8

        mov r8, rax
        shr rax, 3
        mov r9, rax
        shl rax, 3
        sub r8, rax

        mov r11, r8
        cmp r11, 4
        jge arg_pointer_arg1_g0
        lea rax, [rel A]
        add r11, rax
arg_pointer_arg1_back_g0:
        mov r8, r11

        mov r11, r9
        cmp r11, 4
        jge arg_pointer_arg2_g0
        lea rax, [rel A]
        add r11, rax
arg_pointer_arg2_back_g0:
        mov r9b, [r11]

        cmp r10b, 0
        je so_mov
        cmp r10b, 4
        je so_add
        ; ...

group1:
        
        mov r9b, al
        shr rax, 8

        mov r8b, al

        shr rax, 3
        mov r10b, al
        shl rax, 3
        sub r8b, al

        mov r11, r8
        cmp r11, 4
        jge arg_pointer_arg1_g1
        lea rax, [rel A]
        lea r11, [r11 + rax]
arg_pointer_arg1_back_g1:
        mov r8, r11

        cmp r10b, 0
        je so_movi

so_mov:
        popf

        mov [r8], r9b

        jmp continue_loop
so_add:
        popf

        add [r8], r9b

        jmp continue_loop

so_movi:
        popf

        mov [r8], r9b

        jmp continue_loop
continue_loop:
        pushf
        inc rdx
        dec rcx
        jnz main_loop

end:
        xor rax, rax

        popf
        mov [rel Z], word 0
        jnz non_zero
        mov [rel Z], word 1
non_zero:
        mov [rel C], word 0
        jnc non_carry
        mov [rel C], word 1
non_carry:
        mov [rel PC], rdx

        mov rax, qword [rel A]

        add rsp, 16
        ret
