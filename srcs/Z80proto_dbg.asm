;;  Z80proto_dbg.asm

    PUBLIC  debug_rst08
    PUBLIC  debug_rst10
    PUBLIC  debug_rst18
    PUBLIC  DEBUGBREAK
    PUBLIC  DEBUGSTOP

;;
;;; for debug routines
;;
debug_rst08:
    ld  c, 7
    out (PO_1), a
    jr  debug_rst_exit

debug_rst10:
    ld  c, 8
    out (PO_1), a
    jr  debug_rst_exit

debug_rst18:
    ld  c, 9
    out (PO_1), a
    jr  debug_rst_exit

debug_rst_exit:
    call    get_SEG_CHR
    out (PO_1), a
    ld  a, 00000100b    ; anode line 0
    out (PO_2), a
;
    pop ix
    ld  (BUF_BREAKPOINT_ADDR), ix
    halt
;
    ret

DEBUGBREAK:
    ld  (REG_BUF+8), ix
    ld  (REG_BUF+10), iy
    pop iy
    pop ix
    dec ix
    ld  (REG_BUF+12), ix ; PC
    push ix ; pushback
    ld  (REG_BUF+14), sp
    pop ix  ; readout
    push    af
    pop ix
    ld  (REG_BUF), ix ; AF
    ld  (REG_BUF+2), bc
    ld  (REG_BUF+4), de
    ld  (REG_BUF+6), hl
    ;
    ld  ix, (BIOS_ADDR_TABLE)
    ;
    ei
    jp  (ix)

DEBUGSTOP:
    ; *** DEBUG ***
    call    get_SEG_CHR
    out (PO_1), a
    jr  debug_rst_exit
    ; *** DEBUG ***

get_PC:
    pop hl              ; HL = PC + 2
    push    hl          ; push back
    dec hl
    dec hl
;
    ret
