;;  Z80proto_im1.asm -- IM1 devices subroutines for Z80proto

    PUBLIC  conf_timer1
    PUBLIC  conf_timer_other
;;
;;; Config i8253
;;
conf_timer1:
    ld a, 01110000b
                ; Counter #1
                ; Read/Write LSB before MSB
                ; Counter Mode 0
                ; Hexadecimal count
    out (i8253_CC), a
;
    ld a, i8253_C1_LSB
    out (i8253_C1), a
    ld a, i8253_C1_MSB
    out (i8253_C1), a
;
    ret

conf_timer_other:
    ld a, 00110000b
                ; Counter #0
                ; Read/Write LSB before MSB
                ; Counter Mode 0
                ; Hexadecimal count
    out (i8253_CC), a
;
    xor a
    out (i8253_C0), a
    out (i8253_C0), a
;
    ld a, 10110000b
                ; Counter #2
                ; Read/Write LSB before MSB
                ; Counter Mode 0
                ; Hexadecimal count
    out (i8253_CC), a
;
    xor a
    out (i8253_C2), a
    out (i8253_C2), a
;
    ret
