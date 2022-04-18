global so_emul

; rdi - code
; rsi - data
; [rsp] - steps
; [rsp + 8] - core
; r8-r11 - A, D, X, Y
; rdx - PC
so_emul:
        test rsp, rsp
        push rcx ; core - [rsp + 40]
        push rdx ; steps - [rsp + 32]

        push 0 ; Y - [rsp + 24]
        push 0 ; X - [rsp + 16]
        push 0 ; D - [rsp + 8]
        push 0 ; A - [rsp]

        pushf

        mov rcx, rdx
        mov rdx, 0

        cmp rcx, 0
        je end
main_loop:
        mov ax, [rdi + 2 * rdx]

        cmp ax, 0x4000
        jl group0
        sub ax, 0x4000
        cmp ax, 0x4000
        jl group1

group0:
        mov r10b, al

        ; r8 - arg1, r9 - arg2
        shr rax, 8
        mov r9, rax
        shr rax, 3
        mov r8, rax
        shl rax, 3
        sub r9, rax
        shl r9, 3

        cmp r10b, 0
        je so_mov
        ; ...

group1:
        mov r9b, al
        shr rax, 8

        xor r8, r8
        mov r8b, al

        shr rax, 3
        mov r10b, al
        shl rax, 3
        sub r8b, al

        cmp r10b, 0
        je so_movi

so_mov:
        popf

        mov r9, [rsp + 8 * r9]
        mov [rsp + 8 * r8], r9

        jmp continue_loop
so_movi:
        popf

        mov [rsp + 8 * r8], r9b

        jmp continue_loop
continue_loop:
        pushf
        inc rdx
        loop main_loop

end:
        xor rax, rax

        popf
        jnz non_zero
        lea rax, [rax + 1]
non_zero:
        shl rax, 8

        jnc non_carry
        lea rax, [rax + 1]
non_carry:
        shl rax, 16

        lea rax, [rax + rdx]
        shl rax, 8

        mov r8, [rsp + 24]
        lea rax, [rax + r8]
        shl rax, 8

        mov r8, [rsp + 16]
        lea rax, [rax + r8]
        shl rax, 8

        mov r8, [rsp + 8]
        lea rax, [rax + r8]
        shl rax, 8
        
        mov r8, [rsp]
        lea rax, [rax + r8]

        add rsp, 48
        ret
