;; command_m.asm -- 'M' command implement for MiniMon
;
    include "../memmap.def"

    PUBLIC  modify_cons
    EXTERN  p_ix2bc
    EXTERN  loader_cons_oneliner
modify_cons: ;   modify addr
; Mnnnnxx : modify memory data xx to address nnnn
    ld  ix, BUF_CON
    inc ix
    call    p_ix2bc
;
    push    bc
;
    call    p_ix2bc
;
    ld  a, b
    pop hl
    ld  (hl), a
;
    jp  loader_cons_oneliner
