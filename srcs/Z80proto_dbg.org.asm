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

if DEBUG_PPIOUT == 1
_DEBUG_PPIOUT_SETUP:
DEBUG_PPIOUT_SETUP:
    di
    ;
    push    af
    push    bc
    push    hl
    ld a, 10011001b ; Group A&B mode0, PB = OUTPUT
    out (DEBUG_PPICTRL), a
;   

LCD_ES  EQU 5
LCD_RS  EQU 6
LCD_RW  EQU 7
; DB4~7 EQU 0123
    ld  hl, HD44780INIT
    ld  c, DEBUG_PPIPB
    ;
    ld  b, 3
DEBUG_PPIOUT_SETUP_2:
    ld  a, (hl)
    inc hl
    res LCD_RW, a
    out (c), a
    nop
    set LCD_ES, a
    out (c), a
    nop
    res LCD_ES, a
    out (c), a
    nop
    ;
    push    bc
    ld  bc, 4F0h ; approx. 1.5msec/8MHz
    call    sloop
    pop bc
    ;
    djnz    DEBUG_PPIOUT_SETUP_2

    ;
    ld  hl, HD44780INIT_2
    ld  b, 12
DEBUG_PPIOUT_SETUP_3:
    ld  a, (hl)
    inc hl
    res LCD_RW, a
    out (c), a
    nop
    set LCD_ES, a
    out (c), a
    nop
    res LCD_ES, a
    out (c), a
    nop
    ;
    push    bc
    ld  bc, 1CCh ; approx. 6.9msec/8MHz
    call    sloop
    pop bc
    ;
    djnz    DEBUG_PPIOUT_SETUP_3
    ;
    pop hl
    pop bc
    pop af
    ;
    ei
    ret

HD44780INIT:
    defb    0000b, 0011b, 0011b
HD44780INIT_2:
    defb    0011b, 0010b, 0010b, 1000b
    defb    0000b, 1000b, 0000b, 0001b 
    defb    0000b, 0110b, 0000b, 1100b

DEBUG_PBOUT: ; A = output
    di
    ;
    push    af
    srl a
    srl a
    srl a
    srl a
    res LCD_RW, a
    set LCD_RS, a
    out (DEBUG_PPIPB), a
    nop
    set LCD_ES, a
    out (DEBUG_PPIPB), a
    nop
    res LCD_ES, a
    out (DEBUG_PPIPB), a
    nop
    ;
    pop af
    and 0Fh
    res LCD_RW, a
    set LCD_RS, a
    out (DEBUG_PPIPB), a
    nop
    set LCD_ES, a
    out (DEBUG_PPIPB), a
    nop
    res LCD_ES, a
    out (DEBUG_PPIPB), a
    ;
    ei
    ret
endif
