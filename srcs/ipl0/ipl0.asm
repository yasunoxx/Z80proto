;   ipl0.asm -- IPL 0 on ROM for Z80proto
;   (C)2024 yasunoxx▼Julia
;   assemble: zcc +embedded --no-crt ipl0.asm -o ipl0.bin

PIO_0       EQU 00h
PIO_1       EQU 01h
PIO_2       EQU 02h
ROMSEL      EQU 08h
PAGE1       EQU 09h

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
;;  check PAYLOAD ... DEBUGSTOP when invalid PAYLOAD.
    ld  a, (PAYLOAD)
    cp  0EDh    ; PAYLOAD magic(im2 or im1)
    jr  z, blockcopy
    ld  a, 00010010b
    jr DEBUGSTOP
;
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
    and b
    jr  nz, memclr2x

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

    defs    47

;   NMI
;    ORG 0066h
nmi:
    ld  a, 10010010b
    jp  DEBUGSTOP
    halt

    defs    20

DEBUGSTOP:
    ; *** DEBUG ***
    out (PIO_1), a
    ld  a, 00000100b
    out (PIO_2), a
    halt
    ; *** DEBUG ***
    jr  DEBUGSTOP       ; ignore it.
