;;
;;; SIO & CTTC subroutines
;;
;    include "../z80sioctc.def"
;    include "../memmap.def"
    PUBLIC  analyze_SIO0
    PUBLIC  putchar_SIO0
    PUBLIC  getchar_SIO0
    PUBLIC  puts_SIO0
    PUBLIC  gets_SIO0
    PUBLIC  putAreg2chrs
    PUBLIC  conf_CTC
    PUBLIC  conf_SIO

conf_CTC:
    ld  a, 3    ; Ch. Reset
    out(CTC_Ch0), a
    out(CTC_Ch1), a
    out(CTC_Ch2), a
    out(CTC_Ch3), a
;
    xor a       ; Interrupt Vector MSB
    ld  i, a
    ld  a, INTCTC & 00FFh  ; Interrupt Vector LSB
    out(CTC_Ch0), a
;
conf_CTC_Ch0:
if TARGET_Z80PROTO == 2
    ld  a, 10000111b
                ; Ch0
                ; Interrupt Enable
                ; Timer Mode
                ; Prescaler SYSCLK/16
                ; Down Edge
                ; No Trigger Start
                ; Next: Time Constant
                ; Reset Enable, Timer start when write Time Constant
                ; This is configuration, not Interrupt Vector
    out(CTC_Ch0), a
    ld  a, 250  ; 1/((16*250)/4000000) = 1000, 1msec/Interrupt
endif
if (TARGET_SAKI80 == 1|TARGET_Z84C01X == 1)
    ld  a, 10100111b
                ; Ch0
                ; Interrupt Enable
                ; Timer Mode
                ; Prescaler SYSCLK/256
                ; Down Edge
                ; No Trigger Start
                ; Next: Time Constant
                ; Reset Enable, Timer start when write Time Constant
                ; This is configuration, not Interrupt Vector
    out(CTC_Ch0), a
    ld  a, 31  ; 1/((256*31)/8000000) = 1008.064, 1msec/Interrupt
endif
    out(CTC_Ch0), a
;
    ret
;

if TARGET_Z80PROTO == 2
conf_CTC_Ch1: ;; call from conf_SIO_Ch0
    ld  a, 01000111b
                ; Interrupt Disable
                ; Counter Mode
                ; Down Edge
                ; Next: Time Constant
                ; Reset Enable, Counter start when write Time Constant
                ; This is configuration, not Interrupt Vector
    out(CTC_Ch1), a
    ld  a, CTC_SIO0_PRESC
    out(CTC_Ch1), a
;
    ret

conf_CTC_Ch2: ;; call from conf_SIO_Ch1
    ld  a, 01000111b
                ; same as CTC_Ch1
    out(CTC_Ch2), a
    ld  a, CTC_SIO0_PRESC
    out(CTC_Ch2), a
;
    ret
endif

if TARGET_SAKI80 == 1
conf_CTC_Ch3: ;; call from conf_SIO_Ch0
    ld  a, 00000111b
                ; Interrupt Disable
                ; Timer Mode
                ; Prescaler SYSCLK/16
                ; Negative edge start, begins rising edge of T2
                ; Next: Time Constant
                ; Reset Enable, Counter start when write Time Constant
                ; This is configuration, not Interrupt Vector
    out(CTC_Ch3), a
    ld  a, CTC_SIO0_PRESC
    out(CTC_Ch3), a
;
    ret
endif

conf_SIO:
;;  Ch0 configure
if TARGET_Z80PROTO == 2
    call    conf_CTC_Ch1
endif
if TARGET_SAKI80 == 1
    call    conf_CTC_Ch3
endif
;
    ld  b, 12
    ld  c, SIO_Ch0_C
    ld  hl, SIO0_CONF
    otir
;
if TARGET_Z80PROTO == 2
;;  Ch1 configure
;   Set CTC_Ch2
    call    conf_CTC_Ch2
;
    ld  b, 6
    ld  c, SIO_Ch1_C
    ld  hl, SIO1_CONF
    otir
endif
;
    ret

SIO1_CONF:
;   WR0, channel reset
    defb    0
    defb    00011000b
;   WR2, Interrupt Vector
    defb    2
    defb    INTSIO & 00FFh
;   WR1, Wait/Ready functions and Interrupt behavior
    defb    1
    defb    0           ; disable all(TORIAEZU)

SIO0_CONF:
;   WR0, channel reset
    defb    0
    defb    00011000b
;   WR2, Interrupt Vector(but Ch0 is not effect)
    defb    2
    defb    0
if TARGET_Z80PROTO == 2
;   WR4, Rx and Tx control
    defb    4
    defb    01000100b   ; x16 clock, Async. Mode 1 stop bit, non parity
endif
if (TARGET_SAKI80 == 1|TARGET_Z84C01X == 1)
;   WR4, Rx and Tx control
    defb    4
    defb    00000100b   ; x1 clock, Async. Mode 1 stop bit, non parity
endif
;   WR3, Receiver Logic control
    defb    3
    defb    11000001b   ; Rx 8bit, not Auto Enables, Rx enable
;   WR5, Transmit control
    defb    5
    PUBLIC  SIO0_WR5
SIO0_WR5:
    defb    01101000b   ; Tx 8bit, Tx enable
;   WR1, Wait/Ready functions and Interrupt behavior
    defb    1
if SIO_RX_INT == 0
    defb    00000000b   ; Wait/Ready disable, no Rx INT
                        ; Tx INT & Ext./Stat. INT disable
endif
if SIO_RX_INT == 1
    defb    00011000b   ; Wait/Ready disable, Rx INT on All receive character,
                        ; but parity error is not sp. condx.,
                        ; Tx INT & Ext./Stat. INT disable
endif

analyze_SIO0:   ;; get status flags, and reset error
    push    af
    push    bc
    push    ix
    ld  ix, F_STAT_SIO0
;
    xor a
    out (SIO_Ch0_C), a
    ld  a, 00000000b    ; Select RR0
    out (SIO_Ch0_C), a
;
    in  a, (SIO_Ch0_C)
    ld  c, a
analyze_SIO0_RR0_bit0: ;;　read status and error recovery
;    bit 0, c    ; Receive Character Available
;;   FIX: this bit is no effect(interrupt mode)
;    jr  z, analyze_SIO0_RR0_bit1
;
    ; Receive Flag Set
;    set F_STAT_RECEIVE, (ix)
;
analyze_SIO0_RR0_bit1:
    bit 1, c
    jr  z, analyze_SIO0_RR0_bit2
;
    xor a
    out (SIO_Ch0_C), a
    ld  a, 00101000b    ; Reset TxINT Pending
    out (SIO_Ch0_C), a
;
analyze_SIO0_RR0_bit2:
    bit 2, c
    jr  z, analyze_SIO0_RR0_bit6
;
    ; TxBuf Empty Flag Set
    set F_STAT_TXEMPTY, (ix)
;
analyze_SIO0_RR0_bit6:
    bit 6, c
    jr  z, analyze_SIO0_RR0_bit7
;
    xor a
    out (SIO_Ch0_C), a
    ld  a, 11010000b    ; Reset Transmit Underrun and Ext/Stat. Int.
    out (SIO_Ch0_C), a
;
analyze_SIO0_RR0_bit7:
    bit 7, c
    jr  z, analyze_SIO0_RR1
;
    ; Receive Break
    xor a
    out (SIO_Ch0_C), a
    ld  a, 00010000b    ; Reset Ext/Stat. Int.(see manual p296)
    out (SIO_Ch0_C), a
    set F_STAT_BREAK, (ix)
;
analyze_SIO0_RR1:
    xor a
    out (SIO_Ch0_C), a
    ld  a, 00000001b    ; Select RR1
    out (SIO_Ch0_C), a
;
    in  a, (SIO_Ch0_C)
    ld  a, c
analyze_SIO0_RR1_bit0:
    bit 0, c
    jr  z, analyze_SIO0_RR1_bit456
;
    ; Tx All sent flag set
    set F_STAT_ALLSENT, (ix)
;
analyze_SIO0_RR1_bit456:
    ld  a, c
    and  01110000b
    jr  z, analyze_SIO0_end
;
analyze_SIO0_RR1_bit456_e: ; Parity Error, Receive Overrun Error or Framing Error
    xor a
    out (SIO_Ch0_C), a
    ld  a, 00110000b    ; Reset Error
    out (SIO_Ch0_C), a
;
analyze_SIO0_end:
    pop ix
    pop bc
    pop af
;
    ret

    PUBLIC  _putchar_SIO0
_putchar_SIO0:
    ld  a, l
    push    af
    jr  putchar_SIO0_0
;
    PUBLIC  putchar_SIO0
putchar_SIO0: ;;  A = Transmit Character
    push    af
putchar_SIO0_0:
    push    ix
    ld  ix, F_STAT_SIO0
putchar_SIO0_1:
    call    analyze_SIO0
    bit F_STAT_TXEMPTY, (ix)
    jr  z, putchar_SIO0_1

putchar_SIO0_2:
    res F_STAT_TXEMPTY, (ix)
;
    pop ix
    pop af
;
    ; transmit
    out (SIO_Ch0_D), a
;
    ret

    PUBLIC  _getchar_SIO0
_getchar_SIO0:
getchar_SIO0: ;;  A = Receive Character
    push    bc
    xor a
    ld  (BUF_GETCHAR_SIO0+1), a
if SIO_RX_INT == 0
    xor a
    out (SIO_Ch0_C), a
    in  a, (SIO_Ch0_C)
    bit 0, a
    jr  z, getchar_SIO0_norecv
getchar_SIO0_2:
;    ; Send XOFF
;    ld  a, 5
;    out (SIO_Ch0_C), a
getchar_SIO0_2_2:
;    in  a, (SIO_Ch0_C)
;    bit 2, a
;    jr  z, getchar_SIO0_2_2
;    ld  a, XOFF
;    call    putchar_SIO0
    ; Set RTS(RFR) and DTR
    ld  a, 5
    out (SIO_Ch0_C), a
    ld  a, (SIO0_WR5)
    set BIT_RTS, a
    set BIT_DTR, a
    out (SIO_Ch0_C), a

    ; data receive and analyze
    in  a, (SIO_Ch0_D)
    ld  (BUF_GETCHAR_SIO0), a
    call    analyze_SIO0

    push    af
;    ; Send XON
;    ld  a, 5
;    out (SIO_Ch0_C), a
getchar_SIO0_2_3:
;    in  a, (SIO_Ch0_C)
;    bit 2, a
;    jr  z, getchar_SIO0_2_3
;    ld  a, XON
;    call    putchar_SIO0
    ; Reset RTS(RFR) and DTR
    ld  a, 5
    out (SIO_Ch0_C), a
    ld  a, (SIO0_WR5)
    res BIT_RTS, a
    res BIT_DTR, a
    out (SIO_Ch0_C), a
    pop af
endif
if SIO_RX_INT == 1
; Compare Read Pointer and Write Pointer
    ld  a, (PTR_BUF_SIO0_RX_READ)
    ld  b, 0
    ld  c, a
;
    ld  a, (PTR_BUF_SIO0_RX_WRITE)
    sub c
    jr  z, getchar_SIO0_norecv
; Get Receive Character from BUF_SIO0RX
    push    ix
    ld  ix, BUF_SIO0RX
    add ix, bc
    ld  bc, ix  ; BC = BUF_SIO0RX + (PTR_BUF_SIO0_RX_READ)
    pop ix
;
    ld  a, (bc)
    ld  (BUF_GETCHAR_SIO0), a
; Pointer Increment
    ld  a, (PTR_BUF_SIO0_RX_READ)
    inc a
    and 00111111b
    ld  (PTR_BUF_SIO0_RX_READ), a
endif
;
    jr  getchar_SIO0_exit
;
getchar_SIO0_norecv:
    ld  a, NULL
    ld  (BUF_GETCHAR_SIO0), a
    ld  a, 0FFh
    ld  (BUF_GETCHAR_SIO0+1), a
;
getchar_SIO0_exit:
    pop bc
    ld  a, (BUF_GETCHAR_SIO0)
;
    ret

if NOWDEBUG == 1
    PUBLIC  _get_SIO0_polling
_get_SIO0_polling:
    call    getchar_SIO0
    ld      hl, (BUF_GETCHAR_SIO0)
    ld      a, (BUF_GETCHAR_SIO0+1)
    cp      0FFh
    jr      z, _get_SIO0_polling_2
    ret
_get_SIO0_polling_2:
    ld      hl, $ffff
    ret
endif

    PUBLIC  _puts_SIO0
_puts_SIO0:
    ld  hl,2
    add hl,sp   ; skip over return address on stack
    ld  e,(hl)
    inc hl
    ld  d,(hl)   ; de = p
    ld  hl, de

puts_SIO0: ;;  HL = String Addr.(NULL Term.)
    push    af
;
puts_SIO0_loop:
    ld  a, (hl)
    cp  0
    jr  z, puts_SIO0_end
;
    call    putchar_SIO0
    inc hl
    jr  puts_SIO0_loop
;
puts_SIO0_end:
    pop af
;
    ret

gets_SIO0:  ;; IX = *buffer, HL = CNT_BUF_CON
            ;; for usage, see loader_cons_oneliner()
    call    getchar_SIO0
; receive anything ?
    cp  NULL
    jr  z, gets_SIO0 ; nothing
;
    cp  DELETE
    jr  z, del_cons
    cp  BACKSPACE
    jr  z, bs_cons
;
    call    putchar_SIO0    ; echo back
    cp  CR
    jr  z, gets_SIO0_3      ; exit
;
; Other Characters
    cp  'a' - 1
    jr  c, gets_SIO0_1
; Conversion UCASE
    sub 20h
gets_SIO0_1:
    ld  (ix), a ;   A -> (BUF_CON)
;
    ld  a, (hl)
    cp  SIZE_BUF_CON - 1
    jr  c, gets_SIO0_2
;   buffer over, aborted
    dec ix
    dec (hl)
    ;; rewind *RX_BUF ?
    ret                     ; abort
;
gets_SIO0_2:
    inc ix
    inc (hl)    ;   CNT_BUF_CON
;
    jr  gets_SIO0

gets_SIO0_3:
    call    putCRLF
    ret

bs_cons: ;; BACKSPACE
del_cons: ;; DELETE
    ld  hl, CNT_BUF_CON
    ld  a, (hl)
    cp  0
    jr  nz, bs_cons_2
    ld  a, BELL
    call    putchar_SIO0
    jr  gets_SIO0
;
bs_cons_2:
    dec (hl)
    dec ix
;
    ld  a, BACKSPACE
    call    putchar_SIO0    ; echo back
    jr  gets_SIO0

init_SIO_buffers:
    xor a
    ld  (PTR_BUF_SIO0_RX_READ), a
    ld  (PTR_BUF_SIO0_RX_WRITE), a
    ld  (PTR_BUF_SIO1_RX_READ), a
    ld  (PTR_BUF_SIO1_RX_WRITE), a
;
    ret

    PUBLIC  putAreg2chrs
putAreg2chrs:   ; A register -> 2 characters, and put SIO0
    push    af
    push    hl
    push    af
    srl a
    srl a
    srl a
    srl a
    ld  hl, Hexadecimal
    add l
    ld  l, a
    ld  a, (hl)
    call    putchar_SIO0
;
    pop af
    and 0Fh
    ld  hl, Hexadecimal
    add l
    ld  l, a
    ld  a, (hl)
    call    putchar_SIO0
;
    pop hl
    pop af
    ret

    PUBLIC  putCRLF
putCRLF:
    ld  a, CR
    call    putchar_SIO0
    ld  a, LF
    call    putchar_SIO0
    ret
