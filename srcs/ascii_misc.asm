;;  ascii_misc.asm -- ascii <-> binary converion subroutines

    PUBLIC  p_ix2bc
    PUBLIC  nibble2a
    PUBLIC  a2nibble
    PUBLIC  asc2bin
p_ix2bc: ; IX=*(4chrs buffer) to BC, destroy AF
    push    hl
    ld  hl, BUF_ASC2BIN ; for a2nibble(use rld)
;
; BUF_CON+3 -> 4 nibbles
    call    a2nibble
    call    a2nibble
    ld  a, (BUF_ASC2BIN)    ; 2 nibbles
    ld  b, a
    call    a2nibble
    call    a2nibble
    ld  a, (BUF_ASC2BIN)    ; 2 nibbles
    ld  c, a
;
    pop hl
;
    ret

nibble2a: ; 1 nibble -> 1 Hex Char. use HL(rld buffer), destroy IY, BC = char *
    rld

    push    bc
    ld  iy, Hexadecimal
    ld  b, 0
    ld  c, a
    add iy, bc
    pop bc
    ld  a, (iy)

    ld  (bc), a
    inc bc
;
    ret

a2nibble: ; 1 Hex char. -> 1 nibble, use HL(set rld buffer *), IX = char *
    ld  a, (ix)
    call    asc2bin
; and store to BUF_ASC2BIN & rotate
    rld
    inc ix
;
    ret

asc2bin: ; A = Conversion ASCII Chr., return binary
    cp  'A' - 1
    jr  nc, asc2bin_A2F
; not A~F
    sub '0'
;
    ret
;
asc2bin_A2F:
    sub 'A'
    add 10
;
    ret
