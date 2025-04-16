;; command_m.asm -- 'M' command implement for MiniMon
;
    include "../z80sioctc.def"
    include "../memmap.def"

    PUBLIC dump_cons
    EXTERN  p_ix2bc
    EXTERN  de2buf_sio0tx
    EXTERN  putchar_SIO0
    EXTERN  puts_SIO0
    EXTERN  loader_cons_oneliner
dump_cons:
; Dnnnn : memory dump nnnn~+127 bytes
    ld  ix, BUF_CON
    inc ix
    call    p_ix2bc
;
    ld  de, bc  ; dump start address
;
; dump 128 bytes, 16 bytes x 8 lines
    ld  b, 8
dump_cons_loop: ; Address
    call    de2buf_sio0tx
    push    hl
    ld  hl, BUF_SIO0TX
    call    puts_SIO0
    pop hl
;
    ld  a, ':'
    call    putchar_SIO0
; output 16 bytes and Increment
    call    dump_cons3
    push    hl
    ld  hl, 16
    add hl, de
    ex  de, hl
    pop hl
    djnz    dump_cons_loop
;
    jp  loader_cons_oneliner

dump_cons3: ; output 4bytes x 4
    push    bc
    push    de
    push    ix
;
dump_cons3_2:
    ld  b, 8
    ld  ix, de

dump_cons3_3:
    ld  a, (ix)
    ld  d, a
    inc ix
    ld  a, (ix)
    ld  e, a
    inc ix
;
    call    de2buf_sio0tx
    push    hl
    ld  hl, BUF_SIO0TX
    call    puts_SIO0
    pop hl
;
    ld  a, b
    cp  7
    jr  z, dump_cons3_4
    cp  5
    jr  z, dump_cons3_4
    cp  3
    jr  z, dump_cons3_4
    jr  dump_cons3_5
dump_cons3_4:
    ld  a, ' '
    call    putchar_SIO0
dump_cons3_5:
    djnz    dump_cons3_3
;
    ld  a, CR
    call    putchar_SIO0
    ld  a, LF
    call    putchar_SIO0
;
    pop ix
    pop de
    pop bc
;
    ret
