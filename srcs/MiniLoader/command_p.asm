;; command_p.asm -- 'P' command implement for MiniMon
;
    include "../z80sioctc.def"
    include "../memmap.def"

    PUBLIC inout_port_cons
    EXTERN  p_ix2bc
    EXTERN  puts_SIO0
    EXTERN  putchar_SIO0
    EXTERN  Hexadecimal
    EXTERN  STR_error
    EXTERN  loader_cons_oneliner
inout_port_cons: ;   read/write I/O
; PInn, POnnxx : read I/O address 'nn'
;                or write I/O address 'nn' data 'xx'
    ld  ix, BUF_CON
    inc ix
    ld  a, (ix)
    inc ix
    cp  'I'
    jr  z, in_port_cons
    cp  'O'
    jr  z, out_port_cons
; invalid, return cons
    ld  hl, STR_error
    call    puts_SIO0
    jp  loader_cons_oneliner

in_port_cons:
    call    p_ix2bc
;
    ld  c, b
    ld  b, 0
    in  a, (c)
;
    call    putAreg2chrs
;
    ld  a, CR
    call    putchar_SIO0
    ld  a, LF
    call    putchar_SIO0
;
    jp  loader_cons_oneliner

out_port_cons:
    call    p_ix2bc
;
    ld  a, c
    ld  c, b
    ld  b, 0
    out (c), a
;
    jp  loader_cons_oneliner

