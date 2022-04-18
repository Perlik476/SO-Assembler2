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
        mov rdx, 0

        cmp rcx, 0
        je end
main_loop:
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

        mov r8b, al

        shr rax, 3
        mov r10b, al
        shl rax, 3
        sub r8b, al

        cmp r10b, 0
        je so_movi

so_mov:
        popf

        lea r11, [rel A]
        mov r9, [r11 + r9]
        mov [r11 + r8], r9

        jmp continue_loop
so_movi:
        popf

        lea r11, [rel A]
        mov [r11 + r8], r9b

        jmp continue_loop
continue_loop:
        pushf
        inc rdx
        loop main_loop

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
