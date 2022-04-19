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
        xor ah, ah
        add ah, [rel Z]
        shl ah, 6
        add ah, [rel C]
        sahf

        push rcx ; core - [rsp + 8]
        push rdx ; steps - [rsp]



        pushf

        mov rcx, rdx
        mov dl, [rel PC]

        ; mov word [rel Y], 21
        ; rcr word [rel Y], 1
        ; jmp end

        cmp rcx, 0
        je end
main_loop:
        xor rax, rax
        mov ax, [rdi + 2 * rdx]

        xor r8, r8
        xor r9, r9

        cmp ax, 0x4000
        jb group0
        sub ax, 0x4000
        cmp ax, 0x4000
        jb group1
        sub ax, 0x4000
        cmp ax, 0x4000
        jb group2
        sub ax, 0x4000
        jmp group3

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
        jae arg_pointer_arg1_g0
        lea rax, [rel A]
        add r11, rax
arg_pointer_arg1_back_g0:
        mov r8, r11

        mov r11, r9
        cmp r11, 4
        jae arg_pointer_arg2_g0
        lea rax, [rel A]
        add r11, rax
arg_pointer_arg2_back_g0:
        mov r9b, [r11]

        cmp r10b, 0
        je so_mov
        cmp r10b, 2
        je so_or
        cmp r10b, 4
        je so_add
        cmp r10b, 5
        je so_sub
        cmp r10b, 6
        je so_adc
        cmp r10b, 7
        je so_sbb
        ; ...

so_mov:
        popf
        mov [r8], r9b
        jmp continue_loop
so_or:
        popf
        or [r8], r9b
        jmp continue_loop
so_add:
        popf
        add [r8], r9b
        jmp continue_loop
so_sub:
        popf
        sub [r8], r9b
        jmp continue_loop
so_adc:
        popf
        adc [r8], r9b
        jmp continue_loop
so_sbb:
        popf
        sbb [r8], r9b
        jmp continue_loop

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
        jae arg_pointer_arg1_g1
        lea rax, [rel A]
        lea r11, [r11 + rax]
arg_pointer_arg1_back_g1:
        mov r8, r11

        cmp r10b, 0
        je so_movi
        cmp r10b, 3
        je so_xori
        cmp r10b, 4
        je so_addi
        cmp r10b, 5
        je so_cmpi
        cmp r10b, 6
        je so_rcr

so_movi:
        popf
        mov [r8], r9b
        jmp continue_loop
so_xori:
        popf
        xor [r8], r9b
        jmp continue_loop
so_addi:
        popf
        add [r8], r9b
        jmp continue_loop
so_cmpi:
        popf
        cmp [r8], r9b
        jmp continue_loop
so_rcr:
        popf
        mov r9b, [r8]
        rcr r9b, 1
        mov [r8], r9b
        jmp continue_loop

group2:
        cmp ax, 0
        jz so_clc
        jnz so_stc
so_clc:
        popf
        clc
        jmp continue_loop
    
so_stc:
        popf
        stc
        jmp continue_loop

group3:
        mov r8b, al
        shr rax, 8

        cmp al, 0
        je so_jmp_with_popf
        cmp al, 2
        je so_jnc
        cmp al, 3
        je so_jc
        cmp al, 4
        je so_jnz
        cmp al, 5
        je so_jz
        jmp brk

so_jmp:
        pushf
        add dl, r8b
        popf
        jmp continue_loop
so_jmp_with_popf:
        add dl, r8b
        popf
        jmp continue_loop
so_jnc:
        popf
        jnc so_jmp
        jmp continue_loop
so_jc:
        popf
        jc so_jmp
        jmp continue_loop
so_jnz:
        popf
        jnz so_jmp
        jmp continue_loop
so_jz:
        popf
        jz so_jmp
        jmp continue_loop
brk:
        jmp end

continue_loop:
        pushf
        inc dl
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
        mov [rel PC], dl

        mov rax, qword [rel A]

        add rsp, 16
        ret
