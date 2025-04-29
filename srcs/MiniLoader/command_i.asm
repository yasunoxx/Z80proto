;; command_i.asm -- ':' command implement for MiniMon
;
    include "../memmap.def"

    PUBLIC  ihex_load
    EXTERN  p_ix2bc
    EXTERN  putchar_SIO0
    EXTERN  puts_SIO0
    EXTERN  putAreg2chrs
    EXTERN  STR_error
    EXTERN  loader_cons_oneliner
ihex_load:
; :nnnn.... : Intel HEX format text load and store
    ld  ix, BUF_CON
    inc ix      ; forward 1 char
    ; get data counts
    call    p_ix2bc
    ld  a, b
    ld  d, a    ; D = data byte counts 
    ld  e, a    ; E = sum
;    ld  a, 'D'
;    call    putchar_SIO0
    ; get address
    dec ix      ; rewind 2 chars
    dec ix
    call    p_ix2bc
    push    bc  ; BC = store address
    pop     hl  ; HL = store address(previous)
    ld  a, e
    add h
    add l
    ld  e, a
;   get record type
    call    p_ix2bc
    ld      a, b
    ld  a, e
    add b
    ld  e, a
    ld      a, b
    cp  01h
    jr  z, ihex_load_end
    cp  00h
    jr  nz, ihex_load_end
;
ihex_load_2:
    dec ix      ; rewind 2 chars
    dec ix
    call    p_ix2bc
    ld  a, b    ; A = data or checksum
    dec d
    inc d
    jr  z, ihex_load_3
    dec d
    ; data store
    ld      (hl), a
    inc hl
    add e
    ld  e, a    ; writeback sum
    jr  ihex_load_2
;
ihex_load_3:
    ; checksum
    push    af
    ld  a, e
    neg
    ld  e, a
;    call    putAreg2chrs
;    ld  a, 's'
;    call    putchar_SIO0
;    pop af
;    push    af
;    call    putAreg2chrs
;    ld  a, 'c'
;    call    putchar_SIO0
    pop af

    cp  e
    jr  z, ihex_load_end
;
ihex_load_err:
    ld  hl, STR_error
    call    puts_SIO0
;
ihex_load_end:
    jp  loader_cons_oneliner

;;
;; IHEX lines for test
;;
; true:
; :10800000FFFEFDFCFBFAF9F8F7F6F5F4F3F2F1F0F8
; false:
; :10000000FFFEFDFCFBFAF9F8F7F6F5F4F3F2F1F0FF
; ignore:
; :00000001FF
; :02000005000055
; :02000004FFFF55