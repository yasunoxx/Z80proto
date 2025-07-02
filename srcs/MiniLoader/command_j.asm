;; command_j.asm -- 'J' command implement for MiniMon/MiniLoader
;
    .include "common/memmap.def"

    PUBLIC  jump_cons
    EXTERN  p_ix2bc
    EXTERN  loader_cons_oneliner
jump_cons:
; Jnnnn : jump/call 0x0nnnn
    ld  ix, BUF_CON
    inc ix
    call    p_ix2bc
;
    ld  ix, bc  ; target jump address
;
    ld  hl, jump_cons_ret
    push    hl
    jp  (ix)    ; here ld/push/jp(ix) is same as "call (ix)"
jump_cons_ret:
    jp  loader_cons_oneliner
