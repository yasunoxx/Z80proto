;; command_t.asm -- test memory, etc.
  include "../memmap.def"

  PUBLIC  test_mode
  EXTERN  p_ix2bc
  EXTERN  putchar_SIO0
  EXTERN  putCRLF
  EXTERN  putAreg2chrs
  EXTERN  loader_cons_oneliner

PIOBDAT     EQU 1Eh
PIOBCTL     EQU 1Fh

test_mode:
; Tnnnn : test memory area 0x0nnnn to 0x0EFFF
  ld  ix, BUF_CON
  inc ix
  call  p_ix2bc
  push  bc

  ld  a, 00001111b
  out (PIOBCTL), a

memclr:
;; SRAM area zero clear
    pop bc
    ld  de, bc  ; dest.
    push  bc
    ;
    ld  hl, SYSMEM_TOP ; top of system area
    scf
    sbc hl, bc
    ld  bc, hl  ; length
    xor a       ; or as you
    ld  (SYSMEM_TOP), a
    ld  hl, SYSMEM_TOP ; source
memclr2x:
;    ldi
;    dec hl  ; no no, no Increment..

;    ld  a, (hl)

    xor a
    ld  (de), a
    inc de
    dec bc
    ld  a, c
    cp  0
    jr  nz, memclr2x
    ;
    push  hl
    push  bc
    ld  a, d
    srl a
    srl a
    srl a
    srl a
    ld  b, 0
    ld  c, a
    ld  hl, numbers
    adc hl, bc
    ld  a,(hl)
    out (PIOBDAT), a
    pop bc
    pop hl
    ;
    ld  a, c
    and b
    jr  nz, memclr2x
;
;    jr  memclr

    pop bc
    jp  loader_cons_oneliner

if WITH_7SEG == 0
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
endif
