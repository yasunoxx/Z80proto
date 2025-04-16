;   memtest.asm -- Memory Test for Z80proto
;   (C)2024 yasunoxx▼Julia
;   assemble: zcc +embedded --no-crt memtest.asm -o memtest.bin

i8253_C0    EQU 10h
i8253_C1    EQU 11h
i8253_C1_LSB    EQU 40h
i8253_C1_MSB    EQU 9Ch
i8253_C2    EQU 12h
i8253_CC    EQU 13h

CTC_Ch0     EQU 20h
CTC_Ch1     EQU 21h
CTC_Ch2     EQU 22h
CTC_Ch3     EQU 23h
SIO_Ch0_D   EQU 24h
SIO_Ch0_C   EQU 25h
SIO_Ch1_D   EQU 26h
SIO_Ch1_C   EQU 27h
;
PO_0        EQU 00h
PO_1        EQU 01h
PO_2        EQU 02h
ROMSEL      EQU 08h
PAGE1       EQU 09h
PI_0        EQU 0Ch
;
SYSMEM_TOP  EQU 0F000h
PO_2_BUP   EQU 0F800h
PROG_PLACE  EQU 0F801h
V_CNT_16    EQU 0F802h
V_CNT_8A    EQU 0F804h
V_CNT_8B    EQU 0F805h
;
SEG_STATE   EQU 0F810h
SEG_POS     EQU 0F811h
SEG_0       EQU 0F812h
SEG_1       EQU 0F813h
SEG_2       EQU 0F814h
SEG_3       EQU 0F815h
SEG_4       EQU 0F816h
SEG_5       EQU 0F817h

S_SEG_0     EQU 0
S_SEG_1     EQU 1
S_SEG_2     EQU 2
S_SEG_3     EQU 3
S_SEG_4     EQU 4
S_SEG_5     EQU 5

SEG_CHR_0   EQU 0
SEG_CHR_1   EQU 1
SEG_CHR_2   EQU 2
SEG_CHR_3   EQU 3
SEG_CHR_4   EQU 4
SEG_CHR_5   EQU 5
SEG_CHR_6   EQU 6
SEG_CHR_7   EQU 7
SEG_CHR_8   EQU 8
SEG_CHR_9   EQU 9
SEG_CHR_A   EQU 10
SEG_CHR_B   EQU 11
SEG_CHR_C   EQU 12
SEG_CHR_D   EQU 13
SEG_CHR_E   EQU 14
SEG_CHR_F   EQU 15
SEG_CHR_H   EQU 16
SEG_CHR_I   EQU 17
SEG_CHR_J   EQU 18
SEG_CHR_L   EQU 19
SEG_CHR_N   EQU 20
SEG_CHR_O   EQU 21
SEG_CHR_P   EQU 22
SEG_CHR_R   EQU 23
SEG_CHR_T   EQU 24
SEG_CHR_U   EQU 25
SEG_CHR_V   EQU 26
SEG_CHR_X   EQU 27
SEG_CHR_Y   EQU 28
SEG_CHR_Z   EQU 29
SEG_CHR_HYPEN   EQU 30
SEG_CHR_NOUN    EQU 31
SEG_CHR_VERB    EQU 32
SEG_CHR_BLANK   EQU 33

;;
;;;
;;
;   Run on ROM
;    ORG 0h
;   Run on RAM with ipl0.bin
    ORG 0E000h
;   Run on RAM with MiniLoader
;    ORG 0D800h
;
    ld sp, 0h
;    im 1
    im  2
;
    jp main

rst08:
    jp  debug_rst08
;
    defs    5

rst10:
    jp  debug_rst10
;
    defs    5

rst18:
    jp  debug_rst18
;
    defs    5

rst20:
    nop
    ret
;
    defs    6

rst28:
    nop
    ret
;
    defs    6

rst30:
    nop
    ret
;
    defs    6

;
; im1 Interrupts
;
rst38:
isr:
;    ORG 0038h
;
;    ex af, af'
;    exx
    push    af
    push    bc
    push    de
    push    hl

;;  guess who?
    call    int_sci
    call    int_i8253

isr_end:
;;  end ISR
;    exx
;    ex af, af'
    pop hl
    pop de
    pop bc
    pop af
;
    ei
    reti


;    defs    33
    defs    29

;   NMI
;    ORG 0066h
nmi:
;    retn
    jp  DEBUGSTOP
    halt

    defs    6

Vectors:
;   0070h~  CTC
    defw    int_counter
    defw    int_void
    defw    int_void
    defw    int_void
;   0078h~  SIO
    defw    int_void
    defw    int_void
    defw    int_void
    defw    int_void
    defw    int_void
    defw    int_void

    defs    12

;
;   Main routine ?
;
main:
    xor a
    out (PO_0), a
    out (PO_1), a
    out (PO_2), a
    ; pre ROMKICK
    out (ROMSEL), a
    out (PAGE1), a
;
    ld  a, 00000100b    ; Initial PO_2 value
    call    out_PO_2

main1:
;;
;;; Evaluate: ROMKICK(for Z80proto2)
;;
;;  ROMKICK
    ld  a, 00000001b
    out (PO_0), a
    out (ROMSEL), a
    xor a
    out (PO_0), a
;
;; switch to "run on RAM"
;; copy Head block
;; no effect when ROM boot
PAYLOAD     EQU 0E000h
SIZE        EQU 90h
IPL0AREA    EQU 00000h
    ld  hl, PAYLOAD
    ld  de, IPL0AREA
    ld  bc, SIZE
    ldir
    jr  init
;;

;; initialize system devices
init:
    ld  bc, 0789h
    call    sloop
;
;;  for im2
    call    conf_CTC
    call    conf_SIO
;;  for im1
;    call    conf_timer1
;    call    conf_timer_other
;
    call    conf_sysmem
;
    ei

;;
;;; Proto2 title
    ld  c, SEG_CHR_P
    call    get_SEG_CHR
    ld  (SEG_0), a
    ld  c, SEG_CHR_R
    call    get_SEG_CHR
    ld  (SEG_1), a
    ld  c, SEG_CHR_O
    call    get_SEG_CHR
    ld  (SEG_2), a
    ld  c, SEG_CHR_T
    call    get_SEG_CHR
    ld  (SEG_3), a
    ld  c, SEG_CHR_O
    call    get_SEG_CHR
    ld  (SEG_4), a
    ld  c, SEG_CHR_X
    call    get_SEG_CHR
    ld  (SEG_5), a

    call    loop
;
;; Jump to the Application
    jp  memtest80

;; or Halt stop
    nop
    halt


;;
;;  memtest80 -- Memory Test(0080h to 0DFFFh)
;;  

TEST_START_ADDR EQU 0090h
TEST_END_ADDR   EQU 0E000h
TEST_END_ADDR_MSB   EQU 0E0h

memtest80:
;;  title
    ld  c, SEG_CHR_T
    call    get_SEG_CHR
    ld  (SEG_0), a
    ld  c, SEG_CHR_E
    call    get_SEG_CHR
    ld  (SEG_1), a
    ld  c, SEG_CHR_5
    call    get_SEG_CHR
    ld  (SEG_2), a
    ld  c, SEG_CHR_T
    call    get_SEG_CHR
    ld  (SEG_3), a
    ld  c, SEG_CHR_8
    call    get_SEG_CHR
    ld  (SEG_4), a
    ld  c, SEG_CHR_0
    call    get_SEG_CHR
    ld  (SEG_5), a

    call    loop

memtest80_1:
    ld  hl, TEST_START_ADDR
;; disp. Start address
    ld  c, SEG_CHR_T
    call    get_SEG_CHR
    ld  (SEG_0), a
    ld  c, SEG_CHR_HYPEN
    call    get_SEG_CHR
    ld  (SEG_1), a
;
    call    memtest80_3_sub
;
;    ld  c, SEG_CHR_0
;    call    get_SEG_CHR
;    ld  (SEG_2), a
;    ld  c, SEG_CHR_0
;    call    get_SEG_CHR
;    ld  (SEG_3), a
;    ld  c, SEG_CHR_8
;    call    get_SEG_CHR
;    ld  (SEG_4), a
;    ld  c, SEG_CHR_0
;    call    get_SEG_CHR
;    ld  (SEG_5), a

;
;; test -- write and read compare
memtest80_2:
    ld  a, 0AAh
    ld  (hl), a
    ld  a, (hl)
    cp  0AAh
    jp  nz, memtest80_err
;
    ld  a, 55h
    ld  (hl), a
    ld  a, (hl)
    cp  55h
    jp  nz, memtest80_err
;
    ld  a, 3Ch
    ld  (hl), a
    ld  a, (hl)
    cp  3Ch
    jp  nz, memtest80_err
;
    ld  a, 0C3h
    ld  (hl), a
    ld  a, (hl)
    cp  0C3h
    jp  nz, memtest80_err
;
    xor a
    ld  (hl), a
;;  usable??
    inc hl
    ld  a, h
    cp  TEST_END_ADDR_MSB
    jr  z, memtest80_completed
;
    ld  a, l
    cp  0       ; check addr. is xx00h?
    jr  nz, memtest80_2  ; no
;
memtest80_3:
    call    memtest80_3_sub
    jr  memtest80_2

memtest80_3_sub:
;; disp. xx00h
    ld  a, h
    and 11110000b
    srl a
    srl a
    srl a
    srl a
    ld  c, a
    call    get_SEG_CHR
    ld  (SEG_2), a
;
    ld  a, h
    and 00001111b
    ld  c, a
    call    get_SEG_CHR
    ld  (SEG_3), a
;
    ld  a, l
    and 11110000b
    srl a
    srl a
    srl a
    srl a
    ld  c, a
    call    get_SEG_CHR
    ld  (SEG_4), a
;
    ld  a, l
    and 00001111b
    ld  c, a
    call    get_SEG_CHR
    ld  (SEG_5), a
;
    ret

memtest80_completed:
;; disp. end addr
    ld  c, SEG_CHR_C
    call    get_SEG_CHR
    ld  (SEG_0), a
    ld  c, SEG_CHR_D
    call    get_SEG_CHR
;
    dec hl
    call memtest80_3_sub
;    ld  (SEG_2), a
;    ld  c, SEG_CHR_F
;    call    get_SEG_CHR
;    ld  (SEG_3), a
;    ld  c, SEG_CHR_F
;    call    get_SEG_CHR
;    ld  (SEG_4), a
;    ld  c, SEG_CHR_F
;    call    get_SEG_CHR
;    ld  (SEG_5), a
;
memtest80_loop:
;; blink HYPEN on SEG_2
    di
    ld  a, 249
    ld  (V_CNT_8A), a
    ei
memtest80_completed_zombie:
    ld  a, (V_CNT_8A)
    cp  0
    jr  nz, memtest80_completed_zombie
;
    di
    ld  a, 249
    ld  (V_CNT_8A), a
    ei
    ld  c, SEG_CHR_BLANK
    call    get_SEG_CHR
    ld  (SEG_1), a
;
memtest80_completed_zombie2:
    ld  a, (V_CNT_8A)
    cp  0
    jr  nz, memtest80_completed_zombie2
;
    di
    ld  a, 249
    ld  (V_CNT_8A), a
    ei
    ld  c, SEG_CHR_HYPEN
    call    get_SEG_CHR
    ld  (SEG_1), a
;
    jr  memtest80_completed_zombie

memtest80_err:
;; disp. err addr.
    ld  c, SEG_CHR_E
    call    get_SEG_CHR
    ld  (SEG_0), a
    ld  a, h
    and 11110000b
    srl a
    srl a
    srl a
    srl a
    ld  c, a
    call    get_SEG_CHR
    ld  (SEG_2), a
    ld  a, h
    and 00001111b
    ld  c, a
    call    get_SEG_CHR
    ld  (SEG_3), a
    ld  a, l
    and 11110000b
    srl a
    srl a
    srl a
    srl a
    ld  c, a
    call    get_SEG_CHR
    ld  (SEG_4), a
    ld  a, l
    and 00001111b
    ld  c, a
    call    get_SEG_CHR
    ld  (SEG_5), a
;
    jr  memtest80_loop

;;
;;;
;;;;
;;;;; Subroutines
;;;;
;;;
;;
sloop:
    ;; simple loop(BC = loop counts, AF broken)
	dec bc
	ld a,c
	or b
	jr nz,sloop
;
    ret

loop:
    ;; simple loop
sub_05e4h:
	ld bc,8765h
l05e8h:
	dec bc
	ld a,c
    and 00001111b
    cp  00001111b
    jr  nz, l05e8h_2
l05e8h_2:
	ld a,c
	or b
	jr nz,l05e8h
;
    ret

get_SEG_CHR:
    ld  b, 0
;   ld  c, SEG_CHR_?
    ld  ix, numbers
    add ix, bc
    ld  a, (ix)
    ret

numbers:
    defb    11111100b   ;   0
    defb    01100000b   ;   1
    defb    11011010b   ;   2
    defb    11110010b   ;   3
    defb    01100110b   ;   4
    defb    10110110b   ;   5
    defb    10111110b   ;   6
    defb    11100100b   ;   7
    defb    11111110b   ;   8
    defb    11110110b   ;   9
    defb    11101110b   ;   A
    defb    00111110b   ;   b
    defb    10011100b   ;   C
    defb    01111010b   ;   d
    defb    10011110b   ;   E
    defb    10001110b   ;   F
    defb    01101110b   ;   H
    defb    00100000b   ;   i
    defb    01110000b   ;   J
    defb    00011100b   ;   L
    defb    00101010b   ;   n
    defb    00111010b   ;   o
    defb    11001110b   ;   P
    defb    00001010b   ;   r
    defb    00011110b   ;   t
    defb    01111101b   ;   U
    defb    10111001b   ;   v
    defb    10101011b   ;   x
    defb    01110111b   ;   y
    defb    10010011b   ;   Z
    defb    00000010b   ;   -
    defb    11000101b   ;   noun
    defb    01000111b   ;   verb
    defb    0           ;   blank / null termination

;;
;;; Interrupt Service Routines
;;
int_sci:
;;  check SCI
    nop
    ret

int_i8253:
;;  time is up(maybe), re-set counter
    call    conf_timer1
    ret

int_counter:    ; im2
;;
int_counter_16:
    push    af
    push    bc
    push    hl
    push    ix
;;  decrement 16bit value
    ld  hl, (V_CNT_16)
    dec hl
    jr  nc, int_counter_16_end
    ld  hl, 0
int_counter_16_end:
    ld  (V_CNT_16), hl
;
int_counter_8:
;;  decrement 8bit value
    ld  a, (V_CNT_8A)
    dec a
    jr  nc, int_counter_8B
    xor a
int_counter_8B:
    ld  (V_CNT_8A), a
;
    ld  a, (V_CNT_8B)
    dec a
    jr  nc, int_counter_8_end
    xor a
int_counter_8_end:
    ld  (V_CNT_8B), a
;; and drive 7seg
    call    drv_7seg
;; exit
    pop ix
    pop hl
    pop bc
    pop af
    ei
    reti

int_void:   ; im2
;; do nothing
    nop
    ei
    reti

;;
;;; configure I/O devices
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

;;
;;; configure System Memory
;;
conf_sysmem:
    ld  a, 10000000b
                ; set anode line 5(Magic!)
    call    out_PO_2
;
;;  config SEG memories
    ld  a, S_SEG_0
    ld  (SEG_STATE), a
    ld  a, 0            ; Position 0 start
    ld  (SEG_POS), a    ; POSition 0 to 5
    ld  a, 00000010b    ; 7seg display data
    ld  (SEG_0), a
    ld  (SEG_1), a
    ld  (SEG_2), a
    ld  (SEG_3), a
    ld  (SEG_4), a
    ld  (SEG_5), a
;;
    ret

;;
;;; configure Peripherals
;;
out_PO_2:
    out (PO_2), a
                ; OUTPUT anode line
    ld  (PO_2_BUP), a
                ; BACKUP PO_2
;
    ret

conf_CTC:
    ld  a, 3    ; Ch. Reset
    out(CTC_Ch0), a
    out(CTC_Ch1), a
    out(CTC_Ch2), a
    out(CTC_Ch3), a
;
    xor a       ; Interrupt Vector MSB
    ld  i, a
    ld  a, 70h  ; Interrupt Vector LSB
    out(CTC_Ch0), a
;
conf_CTC_Ch0:
    ld  a, 10000111b
                ; Ch0
                ; Interrupt Enable
                ; Timer Mode
                ; Prescaler 1/16φ
                ; Down Edge
                ; No Trigger Start
                ; Next: Time Constant
                ; Reset Enable, Timer start when write Time Constant
                ; This is configuration, not Interrupt Vector
    out(CTC_Ch0), a
    ld  a, 250  ; (16*250)/4000000 = 4000, 1msec/Interrupt
    out(CTC_Ch0), a
;
    ret
;
conf_CTC_Ch1:
;; call from conf_SIO_Ch0
    ld  a, 01000111b
                ; Ch1
                ; Interrupt Disable
                ; Counter Mode
                ; Down Edge
                ; Next: Time Constant
                ; Reset Enable, Counter start when write Time Constant
                ; This is configuration, not Interrupt Vector
    out(CTC_Ch1), a
    ld  a, 13  ; 13/2000000
    out(CTC_Ch1), a
;
    ret

conf_CTC_Ch2:
;; call from conf_SIO_Ch1
    ld  a, 01000111b
                ; Ch2
                ; same as Ch1
    out(CTC_Ch2), a
    ld  a, 13  ; 13/2000000
    out(CTC_Ch2), a
;
    ret

conf_SIO:
;;  channel reset
    ld  a, 00011000b
    out (SIO_Ch0_C), a
    out (SIO_Ch1_C), a
;
;;  Ch0 configure
;   Set CTC_Ch1
    call    conf_CTC_Ch1
    ;   13 counts, SIO prescale is 16, (13*16)/2000000 = 9615.38bps
;   WR1
    ld  a, 1
    out (SIO_Ch0_C), a
    xor a
    out (SIO_Ch0_C), a
;   WR2
    ld  a, 2
    out (SIO_Ch0_C), a
    xor a
    out (SIO_Ch0_C), a
;   WR4
    ld  a, 4
    out (SIO_Ch0_C), a
    ld  a, 44h
    out (SIO_Ch0_C), a
;   WR5~7
    ld  a, 5
    out (SIO_Ch0_C), a
    xor a
    out (SIO_Ch0_C), a
    ld  a, 6
    out (SIO_Ch0_C), a
    xor a
    out (SIO_Ch0_C), a
    ld  a, 7
    out (SIO_Ch0_C), a
    xor a
    out (SIO_Ch0_C), a
;   WR3
    ld  a, 3
    out (SIO_Ch0_C), a
    ld  a, 0C1h
    out (SIO_Ch0_C), a
;
;;  Ch1 configure
;   Set CTC_Ch2
    call    conf_CTC_Ch2
    ;   13 counts, SIO prescale is 16, (13*16)/2000000 = 9615.38bps
;
    ret

;;
;;; Proto2 7seg device drive
;;
drv_7seg:
;;  switch state ... ahh, dirty code.
    xor a
    ld  b, a
    ld  a, (SEG_STATE)
    ld  c, a
;
    cp  S_SEG_0
    jr  z, drv_7seg_S0
    cp  S_SEG_5
    jr  z, drv_7seg_S2
    jr  c, drv_7seg_S1

drv_7seg_S0:    ; output 7seg
;;  get 7seg anode line
    ld  a, (PO_2_BUP)
    call    out_PO_2
    and 11111100b
    sla a
    jr  nc, drv_7seg_S0_1
    ld  a, 00000100b
                ; set anode line 0
drv_7seg_S0_1:
;;  7seg anode line set(post)
    ld  c, a
    ld  a, (PO_2_BUP)
    and 00000011b
                ; erase anode line
    or  c       ; set new anode line
    call    out_PO_2
;
;;  getting cathode data ... get anode line,
    ld  a, (SEG_POS)
    ld  b, 0    ; already
    ld  c, a
;;  set display data pointer,
    ld  ix, SEG_0
    add ix, bc
;;  get cahode data, and output
    ld  a, (ix)
    out (PO_1), a
                ; OUTPUT cathode line

drv_7seg_S1:    ; do nothing
;
    ld  ix, SEG_STATE
    inc (ix)
    jr  drv_7seg_end

drv_7seg_S2:    ; 7seg blanking
    xor a       ; before blanking
    out (PO_1), a
;
    ld  ix, SEG_STATE
    ld (ix), S_SEG_0

drv_7seg_exit:
;;  inclease anode line number
    ld  a, (SEG_POS)
    inc a
    cp  6
    jr  c, drv_7seg_S0_ex2
;;  reset anode line
    xor a
drv_7seg_S0_ex2:
    ld  (SEG_POS), a
;
drv_7seg_end:
    ret

;;
;;; for debug routines
;;
debug_rst08:
    ld  a, 01100000b    ; 1
    out (PO_1), a
    ld  a, 00000100b    ; anode line 0
    out (PO_2), a
    halt
    ret

debug_rst10:
    ld  a, 11011010b    ; 2
    out (PO_1), a
    ld  a, 00001000b    ; anode line 1
    out (PO_2), a
    halt
    ret

debug_rst18:
    ld  a, 11110010b    ; 3
    out (PO_1), a
    ld  a, 00010000b    ; anode line 2
    out (PO_2), a
    halt
    ret

DEBUGSTOP:
    ; *** DEBUG ***
    ld  a, (SEG_STATE)
    out (PO_1), a
    ld  a, 00000100b
    out (PO_2), a
    halt
    ; *** DEBUG ***
    jr  DEBUGSTOP       ; ignore it.

get_PC:
    pop ix              ; IX = PC
    push    ix          ; push back
    dec ix
    dec ix
    dec ix
;
    ret
