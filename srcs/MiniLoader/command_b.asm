;; command_b.asm -- set/reset breakpoint
;
    include "../z80sioctc.def"
    include "../memmap.def"

    PUBLIC  breakp_cons
    EXTERN  p_ix2bc
    EXTERN  puts_SIO0
    EXTERN  STR_error
    EXTERN  loader_cons_oneliner

    DEFC    RST30H = 0F7h

breakp_cons:
; BSnnnn : set breakpoint(rst 30h)
; BR : reset breakpoint
    ld  ix, BUF_CON
    inc ix
    ld  a, (ix)
    inc ix
    cp  'S'
    jr  z, breakpoint_set
    cp  'R'
    jr  z, breakpoint_reset
; invalid, return cons
    ld  hl, STR_error
    call    puts_SIO0
    jp  loader_cons_oneliner

breakpoint_set:
    call    p_ix2bc
    ld  ix, bc
    ld  a, (ix)
    ld  (BUF_BREAKPOINT_OPCODE), a
    ld  (ix), RST30H
    ld  (BUF_BREAKPOINT_ADDR), ix
    jp  loader_cons_oneliner

breakpoint_reset:
    ld  ix, (BUF_BREAKPOINT_ADDR)
    ld  a, (BUF_BREAKPOINT_OPCODE)
    ld  (ix), a
    jp  loader_cons_oneliner
