global polynomial_degree

; stałe w rejestrach, które zostaną ustawione po początkowym etapie:
; r8 - rozmiar utworzonej tablicy do przechowywania dużych liczb w bitach
; r9 - rozmiar utworzonej tablicy do przechowywania dużych liczb w bajtach
; r11 - liczba segmentów 64-bitowych, które reprezentują jedną liczbę

; zmienne w rejestrach:
; rsi - aktualny rozmiar tablicy, tj. ile liczb ma w niej swoją reprezentację

polynomial_degree: ; tablica y w rdi, rozmiar tablicy n w rsi
        ; potrzeba do (n + 32) bitów do zapisu liczb, r11 to liczba 64-bitowych segmentów, która mieści (n + 32) bity.
        lea     rax, [rsi + 32]
        shr     rax, 6
        lea     rax, [rax + 1]
        mov     r11, rax

        mov     rax, r11
        shl     rax, 3
        mul     rsi
        mov     r8, rax
        shr     rax, 3
        mov     r9, rax

        sub     rsp, r8 ; zajmujemy miejsce na tablicę liczb na stosie
        mov     rax, rsp
        mov     rcx, r9

array_all_zeros: ; zerujemy tablicę
        mov     QWORD [rax], 0
        lea     rax, [rax + 8]
        loop    array_all_zeros

        mov     rcx, rsi
        mov     rax, rsp

move_array: ; przenosimy zawartość tablicy y w odpowiednie miejsca utworzonej tablicy
        push    rcx

        ; przenosimy liczbę z tablicy y do pierwszego segmentu odpowiedniego miejsca w tablicy na stosie
        mov     edx, [rdi]
        movsx   r10, edx
        mov     [rax], r10

        cmp     QWORD [rax], 0 ; jeśli wartość liczby jest dodatnia, to nie trzeba zmieniać pozostałych segmentów odpowiadających za tę liczbę
        jge     move_array_next_step

        lea     rdx, [rax + 8]
        mov     rcx, r11
        sub     rcx, 1
        jz move_array_next_step

negative_loop: ; jeśli liczba jest ujemna, to bity w pozostałych segmentach odpowiadających tej liczbie trzeba ustawić na same jedynki
        mov     QWORD [rdx], -1
        lea     rdx, [rdx + 8]
        loop    negative_loop

move_array_next_step: ; przesuwamy wskaźniki do następnych pozycji i powtarzamy pętlę
        lea     rax, [rax + 8 * r11]
        lea     rdi, [rdi + 4]

        pop     rcx
        loop    move_array

        ; etap ustawiania początkowych wartości w tablicy zakończony
        ; teraz będziemy w pętli odejmowali sąsiedznie liczby w tablicy, w każdym kroku uznając, że jej rozmiar zmniejsza się o jedną liczbę. 

        ; w r9 jest aktualny rozmiar tablicy w bajtach, w kolejnych iteracjach będzie się zmniejszać o tyle, ile miejsca zajmuje jedna liczba w tablicy

        ; w r11 jest aktualnie liczba segmentów, z której składa się liczba, więc 8 * r11 jest wartością, o którą trzeba przesunąć wskaźnik, by dostać się do kolejnej liczby w tablicy
        lea     r10, [r9 + 8 * r11]

        mov     rdi, -1 ; w rdi będzie trzymany wynikowy stopień wielomianu
        
        mov     rax, rsp ; ustawiamy rax na początek tablicy ze stosu
        mov     rcx, r9

        jmp     check_zeros_array ; na początek chcemy sprawdzić, czy tablica zawiera same zera

subtract:
        push    rcx
        mov     rcx, r11 ; dla dwóch liczb trzeba odjąć wszystkie odpowiadające segmenty, z których się składają
        clc ; nie interesuje nas flaga przeniesienia z poprzedniej operacji arytmetycznej

subtract_two:
        mov     rdx, [r10]
        sbb     QWORD [rax], rdx ; odejmowanie odpowiadających sobie segmentów sąsiednich liczb z uwzględnieniem flagi przeniesienia

        lea     rax, [rax + 8]
        lea     r10, [r10 + 8]

        loop    subtract_two

        pop     rcx
        loop    subtract

        mov     rax, rsp ; powrót do początku tablicy
        mov     rcx, r9 ; rozmiar aktualnej tablicy
    
check_zeros_array: ; sprawdza w pętli, czy tablica składa się z samych zer
        cmp     QWORD [rax], 0
        jne     non_zero
        lea     rax, [rax + 8]
        loop    check_zeros_array
        jmp     end

non_zero: ; tablica zawiera niezerowy element, trzeba odjąć sąsiednie liczby w tablicy
        sub     r9, r11 ; liczba segmentów w wynikowej tablicy zmniejszy się o liczbę segmentów odpowiadających jednej liczbie
        sub     rsi, 1 ; rozmiar wynikowej tablicy po odejmowaniu zmniejszy się o jeden

        mov     rcx, rsi ; będzie potrzeba wykonać rsi odejmowań liczb
        lea     rdi, [rdi + 1] ; wynikowy stopień wielomianu zwiększamy o jeden

        cmp     rcx, 0 ; jeśli rozmiar aktualnej tablicy wynosi 1, to rcx jest zerem i kończymy program z aktualnym rsi
        je      end

        mov     rax, rsp ; wracamy na początek tablicy w rax
        lea     r10, [rax + 8 * r11] ; wskaźnik na sąsiednią liczbę w tablicy
        jmp     subtract

end:
        mov     rax, rdi ; przenosimy wynik do rax

        add     rsp, r8 ; zwalniamy stos
        ret