global so_emul

section .bss

mem: resq CORES

section .text

arg_pointer:
        push rsi
        lea rsi, [rel mem]
        mov rax, [rsp + 24] ; bo +8 za pushf, +8 za call, +8 za push rsi
        lea rax, [rax * 8]
        add rax, rsi
        pop rsi
        
        cmp r11, 4
        jne check_Y
        mov r11b, [rax + 2]
        lea r11, [rsi + r11]
        ret
check_Y:
        cmp r11, 5
        jne check_XD
        mov r11b, [rax + 3]
        lea r11, [rsi + r11]
        ret
check_XD:
        cmp r11, 6
        jne check_YD
        mov r11b, [rax + 2]
        add r11b, [rax + 1]
        lea r11, [rsi + r11]
        ret
check_YD:
        mov r11b, [rax + 3]
        add r11b, [rax + 1]
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
    

set_flags:
        push rsi
        ; lea rsi, [rel mem]
        ; add rsi, [rsp + 16]

        mov rsi, [rsp + 16]
        lea rsi, [rsi * 8]
        lea rax, [rel mem]
        add rsi, rax

        xor ah, ah
        add ah, [rsi + 7]
        shl ah, 6
        add ah, [rsi + 6]

        sahf
        pop rsi
        ret

set_zf_variable:
        pushf
        lea r10, [rel mem]
        mov rax, [rsp + 16]
        lea rax, [rax * 8]
        add rax, r10
        popf
        mov [rax + 7], byte 0
        jnz .non_zero
        mov [rax + 7], byte 1
.non_zero:
        ret

set_cf_variable:
        pushf
        lea r10, [rel mem]
        mov rax, [rsp + 16]
        lea rax, [rax * 8]
        add rax, r10
        popf
        mov [rax + 6], byte 0
        jnc .non_carry
        mov [rax + 6], byte 1
.non_carry:
        ret

; rdi - code
; rsi - data
; [rsp] - steps
; [rsp + 8] - core
; r8-r11 - A, D, X, Y
; rdx - PC
so_emul:
        push rcx ; core - [rsp]

        call set_flags

        pushf

        mov rcx, rdx
        xor rdx, rdx

        lea r8, [rel mem]
        mov rax, [rsp + 8]
        lea rax, [rax * 8]
        add rax, r8

        mov dl, [rax + 4]

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
        lea r8, [rel mem]
        mov rax, [rsp + 8]
        lea rax, [rax * 8]
        add rax, r8
        add r11, rax
arg_pointer_arg1_back_g0:
        mov r8, r11

        mov r11, r9
        cmp r11, 4
        jae arg_pointer_arg2_g0
        lea r9, [rel mem]
        mov rax, [rsp + 8]
        lea rax, [rax * 8]
        add rax, r9
        add r11, rax
arg_pointer_arg2_back_g0:
        mov r9, r11

        cmp r10b, 8
        je so_xchg

        mov r9b, [r9]

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

so_mov:
        popf
        mov [r8], r9b
        jmp continue_loop
so_or:
        popf
        call set_cf_variable
        call set_zf_variable
        or [r8], r9b
        call set_zf_variable
        call set_flags
        jmp continue_loop
so_add:
        popf
        call set_cf_variable
        call set_zf_variable
        add [r8], r9b
        call set_zf_variable
        call set_flags
        jmp continue_loop
so_sub:
        popf
        call set_cf_variable
        call set_zf_variable
        sub [r8], r9b
        call set_zf_variable
        call set_flags
        jmp continue_loop
so_adc:
        popf
        adc [r8], r9b
        jmp continue_loop
so_sbb:
        popf
        sbb [r8], r9b
        jmp continue_loop
so_xchg:
        popf
        mov al, [r9]
        lock xchg [r8], al
        mov [r9], al
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
        lea r8, [rel mem]
        mov rax, [rsp + 8]
        lea rax, [rax * 8]
        add rax, r8
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
        call set_cf_variable
        call set_zf_variable
        xor [r8], r9b
        call set_zf_variable
        call set_flags
        jmp continue_loop
so_addi:
        popf
        call set_cf_variable
        call set_zf_variable
        add [r8], r9b
        call set_zf_variable
        call set_flags
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

        call set_cf_variable
        call set_zf_variable

        lea r8, [rel mem]
        mov rax, [rsp]
        lea rax, [rax * 8]
        add rax, r8

        mov [rax + 4], dl

        mov rax, qword [rel mem]

        add rsp, 8
        ret
