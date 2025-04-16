;   freertos_crt0.asm -- startup for FreerTOS/Z80proto
;   (C)2024, 2025 yasunoxx▼Julia <yasunoxx gmail>

    include "../Z80proto_bio.def"
    include "../z80sioctc.def"
    include "../z80dma_fdc.def"
    include "../Z80proto_seg.def"
    include "../memmap.def"

;;
;;; Program
;;; !!!DO NOT EDIT ABOVE LINES!!!
;;
rst00:
    include "config.asm"
;
    jp main

    include "../crt_z80_rsts.asm"
;
;
    PUBLIC  __sgoioblk
    PUBLIC  __sgoioblk_end

; Maximum number of FILEs available
IF !DEFINED_CLIB_FOPEN_MAX
    defc    CLIB_FOPEN_MAX = 10
ENDIF

PUBLIC  __FOPEN_MAX
defc    __FOPEN_MAX = CLIB_FOPEN_MAX

; Maximum number of fds available
IF !DEFINED_CLIB_OPEN_MAX
    defc    CLIB_OPEN_MAX = CLIB_FOPEN_MAX
ENDIF

PUBLIC  __CLIB_OPEN_MAX
defc    __CLIB_OPEN_MAX = CLIB_OPEN_MAX
IF CRT_ENABLE_STDIO = 1

    ; Setup std* streams
    ld hl,__sgoioblk+2
    ld (hl),19                  ; stdin
    ld hl,__sgoioblk+12
    ld (hl),21                  ; stdout
    ld hl,__sgoioblk+22
    ld (hl),21                  ; stderr

ENDIF

.__sgoioblk
    defs    CLIB_FOPEN_MAX * 10 ; stdio control block
.__sgoioblk_end                 ; end of stdio control block

; ----------------------------------------------------------------------------
;;
;;;   Main routine ?
;;
; ----------------------------------------------------------------------------
;
main:
    xor a
    out (PO_0), a
    out (PO_1), a
    out (PO_2), a
    ; pre ROMKICK
    out (ROMSEL), a
    out (PAGE1), a
;if FDCDMA == 1
;    out (FD_CONTROL), a ; MOTOR off, etc ...
;endif

;
    ld  a, 00000100b    ; Initial PO_2 value
    call    out_PO_2

if RUN_MODE == RUN_ON_RAM
main1:
;;
;;; Evaluate: ROMKICK(for Z80proto2)
;;
;;  ROMKICK
    ld  a, 00000001b
    out (PO_0), a
    out (ROMSEL), a
;    xor a
;    out (PO_0), a   ; reset output ... 74574 haven't Reset
;

;;;;;;;;
;;;;;;;; !!!!! DANGEROUS EVALUATION !!!!!
;;;;;;;; CHALLENGE 'WRITE TEST 0080H'
;;;;;;;;
main2:
    ld  a, 55h
    ld  (0080h), a
    ld  a, (0080h)
    cp  55h
    jr  nz, main1
;
    ld  a, 0AAh
    ld  (0080h), a
    ld  a, (0080h)
    cp  0AAh
    jr  nz, main1
;
;
;; copy Head block
;; no effect when ROM boot
PAYLOAD     EQU 0E000h
SIZE        EQU 80h
IPL0AREA    EQU 00000h
    ld  hl, PAYLOAD
    ld  de, IPL0AREA
    ld  bc, SIZE
    ldir
;;
endif

;; initialize system devices
    extern  sloop
init:
    ld  bc, 0789h
    call    sloop
;
if INTERRUPT_MODE == 2
;;  for im2
    call    conf_CTC
    call    conf_SIO
endif
if INTERRUPT_MODE == 1
;;  for im1
    call    conf_timer1
    call    conf_timer_other
endif
;
    call    conf_sysmem
;
;    call    spi_dev_unsel
;
;   copy BIOS jump table
    ld  hl, BIOS_TABLE
    ld  de, BIOS_ADDR_TABLE
    ld  bc, BIOS_ADDR_COUNT
    sla c
    rl  b
    ldir
;;
;
    ei

;
;; go to main()
    EXTERN  _main
    jp  _main
;

;;
;;; Interrupt Service Routines, and Peripherals subroutines
;;

;   --------------------------------------------------------------------------
;;
;;; im1 devices
;;
;   --------------------------------------------------------------------------
if  INTERRUPT_MODE == 1

;;; FIXME: add getchar*, putchar*, gets*, puts* routines for im1
int_sci: ;;  check SCI
    nop
;
    ret ; to rst38

int_i8253: ;;  time is up(maybe), re-set counter
    call    conf_timer1
    call    int_counter_dec
;
    PUBLIC  int_timer_hook
int_timer_hook:
    nop
    nop
    nop
;
    ret ; to rst38

    include "../Z80proto_im1.asm"

endif

;   --------------------------------------------------------------------------
;;
;;; im2 devices
;;
;   --------------------------------------------------------------------------
if  INTERRUPT_MODE == 2

int_CTC:
    push    af
    push    bc
    push    hl
    push    ix
;
    call    int_counter_dec
;
    PUBLIC  int_timer_hook
int_timer_hook:
    nop
    nop
    nop
;
    pop ix
    pop hl
    pop bc
    pop af
;
    ei
    reti

int_SIO:
    push    af
    call    analyze_SIO0    ; Get stat and Error Recovery
;
    push    ix
    ld  ix, F_STAT_SIO0
    bit F_STAT_RECEIVE, (ix)
    jr  nz, int_SIO_Ch0_RCA
    jr  int_SIO_exit
;
int_SIO_Ch0_RCA:
    res F_STAT_RECEIVE, (ix)
    push    bc
;
    ld  ix, BUF_SIO0RX
    ld  b, 0
    ld  a, (PTR_BUF_SIO0_RX_WRITE)
    ld  c, a
    add ix, bc
;
    in  a, (SIO_Ch0_D)
    ld  (ix), a
;
    ld  a, c
    inc a
    and 00111111b
    ld  (PTR_BUF_SIO0_RX_WRITE), a
;
    pop bc
    jr  int_SIO_exit

int_SIO_Ch1:
    jr  int_SIO_exit

int_SIO_exit:
    pop ix
    pop af
;
    ei
    reti

int_void:   ; im2, do nothing
    nop
;
    ei
    reti
;
;;
;
    include "../z80sio_sub.asm"

endif
;
;

;
;; common ISR subroutune: counter increment
;
int_counter_dec:
int_counter_16: ;;  16bit value
    ld  hl, (V_CNT_16)
    inc hl
    ld  (V_CNT_16), hl
;
int_counter_8: ;;  8bit value
    ld  a, (V_CNT_8A)
    inc a
    ld  (V_CNT_8A), a
;
    ld  a, (V_CNT_8B)
    inc a
    ld  (V_CNT_8B), a
;
;; exit
    ret

    PUBLIC  _get_int_counter_16
_get_int_counter_16:
    di
    ld  hl, (V_CNT_16)
    ei
    ret

;   --------------------------------------------------------------------------
;;
;;; configure I/O devices, Memory, etc
;;
;   --------------------------------------------------------------------------

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
;;  config SIO Status flag
    xor a
    ld  (F_STAT_SIO0), a
    ld  (F_STAT_SIO1), a
;
;;  config SIO buffers
    call    init_SIO_buffers
;
;;  config int_timer_hook
    ld  ix, int_timer_hook
    xor a
    ld  b, 3
conf_sysmem_1:
    ld  (ix), a
    inc ix
    djnz    conf_sysmem_1
;
    ret

out_PO_2:
    out (PO_2), a
                ; OUTPUT anode line
    ld  (PO_2_BUP), a
                ; BACKUP PO_2
;
    ret


    include "../Z80proto_dbg.asm"
    include "../Z80proto_misc.asm"
    include "../ascii_misc.asm"

BIOS_TABLE:
    defw    0
;   ascii_misc.asm
    defw    p_ix2bc
    defw    nibble2a
    defw    a2nibble
    defw    asc2bin

;   Z80proto_dbg.asm
    defw    debug_rst08
    defw    debug_rst10
    defw    debug_rst18
    defw    DEBUGSTOP

;   Z80proto_misc.asm
    defw    sloop
    defw    loop
    defw    get_SEG_CHR

