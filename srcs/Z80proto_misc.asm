;;  Z80proto_misc.asm

    PUBLIC  sloop
    PUBLIC  loop
    PUBLIC  get_SEG_CHR
;;
;;; Misc. Subroutines
;;
sloop: ;; simple short loop, BC = loop counts, destroy AF
	dec bc
	ld a,c
	or b
	jr nz,sloop
;
    ret

loop: ;; simple long loop, destroy BC
    push    af
sub_05e4h:
	ld bc,8765h
l05e8h:
	dec bc
	ld a,c
    and 00001111b
    cp  00001111b
    jr  nz, l05e8h_2
l05e8h_2:
	ld a,c
	or b
	jr nz,l05e8h
;
    pop af
    ret

get_SEG_CHR: ; C = character code(SEG_CHR_?), destroy A
    push    ix
    ld  b, 0
;   ld  c, SEG_CHR_?
    ld  ix, numbers
    add ix, bc
    ld  a, (ix)
;
    pop ix
    ret

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
    defb    01111101b   ;   U
    defb    10111001b   ;   v
    defb    10101011b   ;   x
    defb    01110111b   ;   y
    defb    10010011b   ;   Z
    defb    00000010b   ;   -
    defb    11000101b   ;   noun
    defb    01000111b   ;   verb
    defb    0           ;   blank / null termination
