;   ipl0.asm -- IPL 0 on ROM for Z80proto
;   (C)2024 yasunoxx▼Julia
;   assemble: zcc +embedded --no-crt ipl0.asm -o ipl0.bin

PIO_0       EQU 00h
PIO_1       EQU 01h
PIO_2       EQU 02h
ROMSEL      EQU 08h
PAGE1       EQU 09h

PIOADAT     EQU 1Ch
PIOACTL     EQU 1Dh
PIOBDAT     EQU 1Eh
PIOBCTL     EQU 1Fh

PAYLOAD     EQU 0100h
SIZE        EQU 0700h
IPL1AREA    EQU 0E000h

;;
;;;
;;
    ORG 0h
;
start:
    ld  bc, 12A0h
sloop:
	dec bc
	ld a,c
	or b
	jr nz,sloop
;
    jp  init_io

;;  check PAYLOAD ... DEBUGSTOP when invalid PAYLOAD.
    ld  a, (PAYLOAD)
    cp  0EDh    ; PAYLOAD magic(im2 or im1)
;    jr  z, blockcopy
    jp  z, memclr
    ld  a, 00010010b
    jr DEBUGSTOP
;
blockcopy:
;;  blockcopy
    ld  hl, PAYLOAD
    ld  de, IPL1AREA
    ld  bc, SIZE
    ldir
;;  and Jump
    ld  hl, IPL1AREA
    jp  (hl)
;;
;;;
;;
        defs    $0066-ASMPC
;   NMI
;    ORG 0066h
nmi:
    ld  a, 10010010b
    jp  DEBUGSTOP
    halt

        defs    $0070-ASMPC
DEBUGSTOP:
    ; *** DEBUG ***
    out (PIO_1), a
    ld  a, 00000100b
    out (PIO_2), a
    halt
    ; *** DEBUG ***
    jr  DEBUGSTOP       ; ignore it.

        defs    $0080-ASMPC
memclr:
;; SRAM area(2000h~) zero clear
    ld  hl, 2000h
    xor a   ; or as you
    ld  (hl), a ; source
    ld  bc, 0E000h  ; length
    ld  de, 2000h   ; dest.
memclr2x:
    ldi
    dec hl  ; no no, no Increment..
    ld  a, c
    cp  0
    jr  nz, memclr2x
    ;
    ld  ix, hl
    ld  a, d
    srl a
    srl a
    srl a
    srl a
    ld  hl, numbers
    ld  l, a
    ld  a,(hl)
    out (PIOBDAT), a
    ld  hl, ix
    ;
    and b
    jr  nz, memclr2x
;
    jr  memclr

init_io:
    ld  a, 00001111b
    out (PIOBCTL), a

    jp  memclr

        defs    $0100-ASMPC
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
