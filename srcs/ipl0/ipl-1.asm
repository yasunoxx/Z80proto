;   ipl-1.asm
;   assemble: zcc +embedded --no-crt ipl-1.asm -o ipl-1.bin

i8253_C0    EQU 10h
i8253_C0_LSB    EQU 012h
i8253_C0_MSB    EQU 0A0h
i8253_C1    EQU 11h
i8253_C2    EQU 12h
i8253_CC    EQU 13h
OUTP_0      EQU 00h
OUTP_1      EQU 01h

    ORG 0h
;
    ld a, 00110000b
    out (i8253_CC), a
    ld a, i8253_C0_LSB
    out (i8253_C0), a
    ld a, i8253_C0_MSB
    out (i8253_C0), a

;
;   Main routine ?
;
main:
    ld ix, numbers
;
main2:
    ld a, (ix)
    cp 0
    jr z, main
    out (OUTP_1), a
;
    jr loop
main3:
    inc ix
    jr main2
;
    nop
    halt
;
loop:
sub_05e4h:
	ld de,01a2ch		;05e5	11 2c 1a 	. , . 
l05e8h:
	dec de			;05e8	1b 	. 
	ld a,e			;05e9	7b 	{ 
	or d			;05ea	b2 	. 
	jr nz,l05e8h		;05eb	20 fb 	  . 
;
	jr main3
;
numbers:
    defb    11111100b   ;   0
    defb    01100000b   ;   1
    defb    11011010b   ;   2
    defb    11110010b   ;   3
    defb    01100110b   ;   4
    defb    10110110b   ;   5
    defb    10111110b   ;   6
    defb    11100100b   ;   7
    defb    11111110b   ;   8
    defb    11110110b   ;   9
    defb    11101110b   ;   A
    defb    00111110b   ;   b
    defb    10011100b   ;   C
    defb    01111010b   ;   d
    defb    10011110b   ;   E
    defb    10001110b   ;   F
    defb    01101110b   ;   H
    defb    00100000b   ;   i
    defb    01110000b   ;   J
    defb    00011100b   ;   L
    defb    00101010b   ;   n
    defb    00111010b   ;   o
    defb    11001110b   ;   P
    defb    00001010b   ;   r
    defb    00011110b   ;   t
    defb    01111100b   ;   U
    defb    10101010b   ;   x
    defb    01110110b   ;   y
    defb    0           ;   null termination
