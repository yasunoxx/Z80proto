; Define the low memory for builds that start at 0x0E000(0x0000)
;
; Allow overriding of:
; - All rsts
; - (including im2)
; - NMI (not 808x)

;
;        PUBLIC  rst00
;        PUBLIC  isr_im1
;
;        EXTERN  debug_rst08
;        EXTERN  debug_rst10
;        EXTERN  debug_rst18
;        EXTERN  DEBUGSTOP
        EXTERN  int_CTC
        EXTERN  int_SIO
        EXTERN  int_void
;
        defs    $0008-ASMPC
rst08:
    jp  debug_rst08
;
        defs    $0010-ASMPC
rst10:
    jp  debug_rst10
;
        defs    $0018-ASMPC
rst18:
    jp  debug_rst18
;
        defs    $0020-ASMPC
rst20:
    nop
    ret
;
        defs    $0028-ASMPC
rst28:
    nop
    ret
;
        defs    $0030-ASMPC
rst30:
    di
    EXTERN  DEBUGBREAK
    call    DEBUGBREAK
;    ret    ; NO RETURN
;
        defs    $0038-ASMPC
;
; im1 Interrupts
;
rst38:
if INTERRUPT_MODE == 1
isr_im1:
    push    af
    push    bc
    push    de
    push    hl

;;  guess who?
;    call    int_sci
;    call    int_i8253

isr_end: ; end ISR
    pop hl
    pop de
    pop bc
    pop af
;
    ei
    reti
endif
if INTERRUPT_MODE == 2
    nop
    ret
endif
;
        defs    $0050-ASMPC
;    ORG 0050h
    PUBLIC  Hexadecimal
Hexadecimal:
    defb    '0'
    defb    '1'
    defb    '2'
    defb    '3'
    defb    '4'
    defb    '5'
    defb    '6'
    defb    '7'
    defb    '8'
    defb    '9'
    defb    'A'
    defb    'B'
    defb    'C'
    defb    'D'
    defb    'E'
    defb    'F'
;
        defs    $0066-ASMPC
nmi:
    ld  c, 16   ;   SEG_CHR_H
    jp  DEBUGSTOP
    halt

    defs    4

        defs    $0070-ASMPC
Vectors:
;   0070h~  CTC
;        PUBLIC  INTCTC
;        PUBLIC  INTSIO
;        PUBLIC  INTDMA
INTCTC:
    defw    int_CTC
    defw    int_void
    defw    int_void
    defw    int_void
;
;   0078h   SIO
INTSIO:
    defw    int_SIO
;
;   007Ah   DMA
INTDMA:
    defw    int_void

        defs    $0080-ASMPC
