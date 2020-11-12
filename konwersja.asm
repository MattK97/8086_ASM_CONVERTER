Progr segment

assume  cs:Progr,ds:dane,ss:stosik

readln proc;
mov ah,0ah
int 21h;
ret
endp

naekran proc
mov ah,09h ;wypisywanie dx na ekran
int 21h ; funkcja 9 wyswietl napis
ret ; powrót do programu gdzie odłożono stack pointer
endp ; koniec procerdury

emptyNumber proc
mov dx,offset msg1
call naekran
jmp koniec
ret
endp

wrongNumber proc
mov dx,offset msg2
call naekran
jmp koniec
ret
endp

toobigNumber proc
mov dx,offset msg3
call naekran
jmp koniec
ret
endp

Start:
	mov ax,dane; adresacja bezposrednia
  mov ds,ax; adresacja bezposrednia
  mov ax,stosik; adresacja bezposrednia
	mov ss,ax; adresacja bezposrednia
	mov sp,offset szczyt; adresacja wzgledna

	lea dx,msg
	call naekran

	lea dx,dl_buf
	call readln

	lea dx,enterr
	call naekran

	CMP ile,0; sprawdzenie czy podany ciag znakow nie jest pusty, jesli tak to wywolac procedure emptyNumber, jezeli nie skocz do etykiety dalej
	jnz  dalej
	call emptyNumber
dalej:
	mov si,0; index 0

czyliczba:
	mov bl,znaki(si); przenies pierwszy znak do rejestru bl
	cmp bl,13; prownuje znak znak z kodem 16 klawisza enter jesli enter to skacz do etykiety koniec_liczby
	jz koniec_liczby
	mov ax,suma ; kopiuj sume do rejestru ax => ax:=suma
	mul dycha; ax:=ax*dycha, czyli * 10 => ax:=ax*10
	jno notOverflow; jezeli brak przepelnienia do skocz do etykiety notOverflow
	call toobigNumber; wywolaj procedure za duza liczba
notOverflow:
	mov suma,ax ; suma:=ax
	sub bl,'0'; bl:=bl-'0'
	mov cyfra,bl; cyfra:=bl
	cmp cyfra,10; jezeli cyfra = lub >10 to wywolaj procedure wrongNumber, jezli 10> to jest liczba i skocz do etykiety isNumber
	jc isNumber
	call wrongNumber
isNumber:
	mov bl,cyfra; bl:=cyfra
	add suma,bx ; suma:=suma+bx
	jnc notOverflow1; jezeli brak przepelnienia to skocz do etykiety notOverflow1
	call toobigNumber; wywolaj procedure toobigNumber
notOverflow1:
	inc si; zwieksz rejestr indeksowy o 1 -> si:=si+1
	cmp si,6; jezli index rowny 6 to skocz do etykiety koniec_liczby, jezeli jest mniejszy to skocz do etykiety czyliczba i sprawdzaj kolejne znaki
	jnz czyliczba
koniec_liczby:

; zamiana z 10 na 2 --------------------------------------------------------------------
;Zamiana liczby w systemie 10 (wynik) na system 2
;Aby wypisac liczbe w postaci binarnej mnozymy ja razy 2
;i sprawdzamy znacznik przeniesienia CF.
;Liczba znajduje sie w rejestrze AX, SI jest to pozycja znaku
;w lancuchu ktora nalezy zmodyfikowac i jednoczesnie licznikiem petli.
;Liczba moze byc zapisana maksymalnie na 16 bitach (0-15) wiec wykonujemy 16 iteracji
;petli.
;========================================================================================

	mov ax,suma ;
	mov si,0
binary:
	shl ax,1; przesun wartosc AX w lewo => AX*2
	jc jedynka; jesli nastapilo przeniesienie skocz do etykiety
	jnc zero; jesli nie bylo przeniesienia skocz do etykiety
dalej_binary:
	lea bx,liczba2; w rejestrze bx jest offset zmiennej liczba2;
	mov ds:[bx+si],dl; przekazanie znaku do zmiennej lancuchowej
	cmp si,15; porownaj si z 15 (maksymalny numer bitu w rejestrze 16-bitowym )
	je end_binary; jesli SI=15 to skocz do etykiety
	inc si; zwieksz SI o 1
	jmp binary;
jedynka:
	mov dl,31h; kod znaku "1"
	jmp dalej_binary;
zero:
	mov dl,30h; kod znaku "0"
	jmp dalej_binary;
end_binary:

; zamiana z 10 na 16 ------------------------------------------------------------------
;zamiana z systemu 10 na 16
; w tym bloku kodu programu rejestr CL pelni role licznika przesuniecia
;logicznego wartosci liczby, rejestr CH jest ogolnym licznikiem petli
;natomiast si jest wskazaniem pozycji w lancuchu tekstu ktory ma byc zmieniony
;przygotowanie rejestrow
;=======================================================================================

	xor cl,cl; zerowanie przesuniecia logicznego
	mov ch,3; ustaw licznik na 3
	mov si,3; ustaw index na 3
hexa:
	mov ax,suma;
	shr ax,cl; przesuniecie rejestru ax o cl miejsc w prawo =>AX:=AX/(2^CL)
	and ax,1111b; maska ktora zeruje czesc liczby wieksza od 15
	cmp al,9; porownanie liczby z 9
	ja litery; jesli liczba > 9 to skocz do etykiety litery
	add al,30h; w przeciwnym wypadku do liczby dodaj kod ASCII znaku '0'
dalej_hexa:
	lea bx,liczba16; w rejestrze bx jest offset zmiennej liczba16;
	mov ds:[bx+si],al; przekazanie znaku do zmiennej lancuchowej
	cmp ch,0; porownaj licznik z 0
	je end_hexa; jesli licznik = 0 to wyjdz z petli
	dec si; si:=si-1;
	dec ch; zmniejsz licznik o 1;
	add cl,4; zwieksz wartosc przesuniecia 0 4
	jmp hexa; nastepna iteracja
litery:
	sub al,10; od liczby odejmnij 10;
	add al,'A'; do liczby dodaj kod ASCII znaku 'A'
	jmp dalej_hexa; skocz do etykiety
end_hexa:
	mov al,'H'; w AL umiesc kod znaku 'H'
	lea bx,liczba16; w rejestrze bx jest offset zmiennej liczba16;
	mov ds:[bx+4],al; przekazanie znaku do zmiennej lancuchowej

; wypiswanie liczby 10, 2, 16 ---------------------------------------------------------
	mov al,dl_buf
	mov ah,0
	mov si,ax
	mov znaki(si),'$'
	mov dx,offset msg4
	call naekran
	mov dx,offset znaki(0)
	call naekran
	lea dx,enterr
	call naekran
	mov dx,offset msg5
	call naekran
	mov dx,offset liczba2(0)
	call naekran
	lea dx,enterr
	call naekran
	mov dx,offset msg6
	call naekran
	mov dx,offset liczba16(0)
	call naekran

koniec:
	mov ah,4Ch
	mov al,0h
	int 21h

Progr ends


dane segment

dl_buf db 6
ile db 0
znaki db 6 dup (0)
dycha dw 10
cyfra db 0
suma dw 0
index dw 0
liczba2 db 16 dup(0)
dolar db '$'
liczba16 db 4 dup(0)
dolar1 db '$'
dolar2 db '$'

msg db 'Prosze podac liczbe z zakresu od 0 do 65535',10,13,'$'
msg1 db 'Nic nie zostalo wpisane','$'
msg2 db 'Zle wpisana liczba',10,13,'$'
msg3 db 'Liczba jest z poza zakresu','$'
msg4 db '   Liczba dziesietnie: $'
msg5 db '   Liczba binarnie: $'
msg6 db '   Liczba hexadecymalnie: $'
enterr db 10,13,'$'

dane ends


stosik segment

		dw 100h dup(0)
szczyt label word

stosik ends
end start
