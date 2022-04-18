global so_emul

.bss



.text

; rdi - code
; rsi - data
; [rsp] - steps
; [rsp + 8] - core
; r8-r11 - A, D, X, Y
; rdx - PC
so_emul:
        push rcx
        push rdx

        mov rcx, rdx
        mov rdx, 0
.main_loop:
        mov rax, [rdi + 2 * rdx]
        inc rdx
        loop .main_loop

        add rsp, 16
        ret
