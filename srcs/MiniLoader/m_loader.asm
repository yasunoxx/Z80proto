;   m_loader.asm -- MiniLoader for Z80proto
;   (C)2024, 2025 yasunoxx▼Julia <yasunoxx gmail>
;   assemble: zcc +embedded --no-crt m_loader.asm -o m_loader.bin -m --list
;             (or 'make')

    include "../Z80proto_bio.def"
    include "../z80sioctc.def"
    include "../Z80proto_seg.def"
    include "../memmap.def"

;;
;;; Program
;;
rst00:
;;  !!!DO NOT EDIT!!!: m_loader.asm is "run on ROM" only
;   run on ROM
    ORG 0h
;
    include "config.asm"
;
    jp main

    include "../crt_z80_rsts.asm"

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
    ; no ROMKICK
    out (ROMSEL), a
    out (PAGE1), a
;
    ld  a, 00000100b    ; Initial PO_2 value
    call    out_PO_2

;; initialize system devices
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
    call    spi_dev_unsel
;
    ei

;;
;;; Proto2 title
;;
    ; Proto2 title
    ld  hl, SEG_TITLE_PROTO2
    ld  de, SEG_0
    ld  bc, 6
    ldir

    call    loop
;

;;
;;; MiniLoader, a small loader
;;

loader: ; Loader title
    ld  hl, SEG_TITLE_LOADER
    ld  de, SEG_0
    ld  bc, 6
    ldir

;; Loader title to SIO0
    ld  hl, STR_loader_title
    call    puts_SIO0
    call    loop
; check AUTOLOAD switch
    in  a, (PI_0)
    bit 2, a
;; branch here
    jp  z, spirom_read00

;;
;;;
;;;; Console Mode
;;;
;;
loader_cons: ; Console title
    ld  hl, SEG_TITLE_CONS
    ld  de, SEG_0
    ld  bc, 6
    ldir
;
loader_cons_oneliner: ; Startup Console one line
    ld  hl, STR_loader_prompt
    call    puts_SIO0
;
    ld  ix, BUF_CON
    ld  hl, CNT_BUF_CON
    xor a
    ld  (hl), a
    call    gets_SIO0

parse_cons: ;; parse command
parse_cons_2:
    ld  hl, CNT_BUF_CON
    ld  a, (hl)
;
    ld  b, 0
    ld  c, a    ; BC = CNT_BUF_CON
    ld  hl, BUF_CON
    add hl, bc  ; HL = BUF_CON + CNT_BUF_CON
    ld  a, NULL
    ld  (hl), a ; NULL termination
    ld  hl, BUF_CON
    ld  a, (hl)
;
parse_cons_3:
    cp  'L'
    jp  z, spirom_loadIndex
    ; L : load FAT0(0x1F0000~) into buffer
    cp  'D'
    jp  z, dump_cons
    ; Dnnnn : memory dump nnnn~+127 bytes
    cp  'J'
    jp  z, jump_cons
    ; Jnnnn : jump
;
;   cp  'M'
;   jp  z, modify_cons
;   ; Mnnnn : modify memory
;   cp  'S'
;   jp  z, upload_srec_1line
;   ; Sxxxx... : S-record type memory modify
;   ; (accept S1, S2, S3 record, ignore other records)
;   cp  'C'
;   jp  z, command_to_spidev
;   ; Cnnxx : send command address 'nn' data 'xx' to device 2
;   cp  'R'
;   jp  z, read_in_spibuf
;   ; Rnnnn : read ROM 0xnnnn00~+255 bytes to buffer
;   cp  'W'
;   jp  z, write_out_spibuf
;   ; Wnnnn : write buffer to ROM 0xnnnn00~+255 bytes
;   cp  'P'
;   jp  z, in_port_cons
;   ; Pnn : read I/O address 'nn'
;   cp  'Q'
;   jp  z, out_port_cons
;   ; Pnnxx : write I/O address 'nn' data 'xx'
;   cp  'O'
;   jp  z, output_srec
;   ; O : output S-record format
;   cp  'N'
;   jp  z, noun_verb_mode
;   ; N : for debug mode ...
;
    jp  loader_cons_oneliner

jump_cons: ;   jump addr
    ld  ix, BUF_CON
    inc ix
    call    p_ix2bc
;
    ld  ix, bc  ; dump start address
    jp  (ix)

dump_cons: ;   dump 128 bytes
    ld  ix, BUF_CON
    inc ix
    call    p_ix2bc
;
    ld  de, bc  ; dump start address
;
; dump 128 bytes, 16 bytes x 8 lines
    ld  b, 8
dump_cons_loop: ; Address
    call    dump_cons2      ; as de2buf_sio0tx
    push    hl
    ld  hl, BUF_SIO0TX
    call    puts_SIO0
    pop hl
;
    ld  a, ':'
    call    putchar_SIO0
; output 16 bytes and Increment
    call    dump_cons3
    push    hl
    ld  hl, 16
    add hl, de
    ex  de, hl
    pop hl
    djnz    dump_cons_loop
;
    jp  loader_cons_oneliner

dump_cons3: ; output 4bytes x 4
    push    bc
    push    de
    push    ix
;
dump_cons3_2:
    ld  b, 8
    ld  ix, de

dump_cons3_3:
    ld  a, (ix)
    ld  d, a
    inc ix
    ld  a, (ix)
    ld  e, a
    inc ix
;
    call    dump_cons2      ; as de2buf_sio0tx
    push    hl
    ld  hl, BUF_SIO0TX
    call    puts_SIO0
    pop hl
;
    ld  a, b
    cp  7
    jr  z, dump_cons3_4
    cp  5
    jr  z, dump_cons3_4
    cp  3
    jr  z, dump_cons3_4
    jr  dump_cons3_5
dump_cons3_4:
    ld  a, ' '
    call    putchar_SIO0
dump_cons3_5:
    djnz    dump_cons3_3
;
    ld  a, CR
    call    putchar_SIO0
    ld  a, LF
    call    putchar_SIO0
;
    pop ix
    pop de
    pop bc
;
    ret

dump_cons2:
de2buf_sio0tx: ; DE(4 nibbles) -> BUF_SIO0TX
    push    bc
    push    hl

    ld  hl, BUF_ASC2BIN
    ld  bc, BUF_SIO0TX
;
    ld  a, d
    ld  (BUF_ASC2BIN), a
    xor a
    call    nibble2a
    xor a
    call    nibble2a
    ld  a, e
    ld  (BUF_ASC2BIN), a
    xor a
    call    nibble2a
    xor a
    call    nibble2a
;
dump_cons2_end:
    ld  a, NULL
    ld  (bc), a
;
    pop hl
    pop bc
;
    ret

;;
;;;
;;;; SPI loader Mode
;;;
;;

;; spirom_loadIndex -- read Index block to BUF_SPIROM
;
spirom_loadIndex:
    call    spirom_readIndex
;; exit
    jp  loader_cons_oneliner

;; spirom_read00 -- Autoboot: Read Sector 00 and execute
spirom_read00:
    call    spirom_setWRSR
;
    ld  a, SPI_DEVID_Ch1
    ld  (SPI_SELD_DEV), a
    call    spi_dev_sel
;
    ld  ix, 1F00h   ; FAT block 0~15
    call    spirom_setAddr
    call    spirom_read256toBUF
;
;;  for debug: display addresses
    ld  de, (BUF_SPIROM + 2)    ; Destination Address
    call    de2buf_sio0tx
    ld  hl, BUF_SIO0TX
    call    puts_SIO0
    ld  a, ','
    call    putchar_SIO0
;
    ld  bc, (BUF_SPIROM + 4)    ; Block Size
    ld  de, bc
    call    de2buf_sio0tx
    ld  hl, BUF_SIO0TX
    call    puts_SIO0
    ld  a, ','
    call    putchar_SIO0
;
    ld  iy, (BUF_SPIROM + 6)    ; Exec. Address
    push    iy
    ld  de, iy
    call    de2buf_sio0tx
    ld  hl, BUF_SIO0TX
    call    puts_SIO0
;
    ld  de, (BUF_SPIROM + 2)    ; reload Destination Address
;
;   reset ROM
    call    spi_dev_unsel
    ld  a, SPI_DEVID_Ch1
    ld  (SPI_SELD_DEV), a
    call    spi_dev_sel
;
    ld  ix, 0       ; sector 0 / block 0
    call    spirom_setAddr
spirom_read00_loop:
    call    spirom_read256toBUF
;
    push    bc
    ld  hl, BUF_SPIROM
    ld  bc, 256
    ldir
;   DE += 256
    pop bc
;
    djnz    spirom_read00_loop
;
    call    spi_dev_unsel
;
    pop iy
    di
    jp  (iy)    ;;; NO RETURN
;    jp  loader_cons

;
;; spirom_ subroutines
;
spirom_readIndex:
    call    spirom_setWRSR
;
    ld  a, SPI_DEVID_Ch1
    ld  (SPI_SELD_DEV), a
    call    spi_dev_sel
;
;    ld  ix, 1F01h   ; FAT block 16~31
    ld  ix, 1F00h   ; FAT block 0~15 for debug
    call    spirom_setAddr
    call    spirom_read256toBUF
;
    call    spi_dev_unsel
;
    ret

spirom_read256toBUF:    ; read (IX) block to BUF_SPIROM
    push    bc
;
    ld  b, 0h
    ld  ix, BUF_SPIROM
spirom_read256_loop:
    call    spi_read_8bit
    ld  (ix), a
    inc ix
;; disp readdata
    ld  a, b
    cpl a
    call    drv_7seg_sub_disp2
;
    djnz    spirom_read256_loop
;
    pop bc
    ret

spirom_setWRSR: ; read on fast read data mode, destroy AF
    ld  a, SPI_DEVID_Ch1
    ld  (SPI_SELD_DEV), a
    call    spi_dev_sel
;
    ld  a, SPIROM_CMD_WRSR
    call    spi_write_8bit
    ld  a, 00000000b    ; SRWD = 0, BP[2:0] = 000, WEL = 0, WIP = 0
    call    spi_write_8bit
;
    call    spi_dev_unsel
;
    ret
;
spirom_setAddr: ; IX = read/wrte addr MSB 16bit(nnnn00h), destroy AF, HL
    ld  a, SPIROM_CMD_FAST_READ
    call    spi_write_8bit
    ld  hl, ix
    ld  a, h    ;   Addr. MSB
    call    spi_write_8bit
    ld  a, l    ;   Addr. middle
    call    spi_write_8bit
    xor a   ;   Addr. LSB
    call    spi_write_8bit
    xor a   ;   dummy byte
    call    spi_write_8bit
;
    ret
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
;; common ISR subroutune: counter decrement
;
int_counter_dec:
int_counter_16: ;;  decrement 16bit value
    ld  hl, (V_CNT_16)
    dec hl
    jr  nc, int_counter_16_end
    ld  hl, 0
int_counter_16_end:
    ld  (V_CNT_16), hl
;
int_counter_8: ;;  decrement 8bit value
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
;
;; and drive 7seg
    call    drv_7seg
;
;; exit
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
    ret

;   --------------------------------------------------------------------------
;;
;;; I/O subroutines
;;
;   --------------------------------------------------------------------------

;;
;;; drv_*: Proto2 7seg device drive
;;
drv_7seg: ;;  switch state ... ahh, dirty code.
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
    ld  a, (PO_2_BUP)   ;; get 7seg anode line
    call    out_PO_2
    and 11111100b
    sla a
    jr  nc, drv_7seg_S0_1
    ld  a, 00000100b
                ; set anode line 0
drv_7seg_S0_1: ;; 7seg anode line set(post)
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
;;  get cathode data, and output
    ld  a, (ix)
    out (PO_1), a
                ; OUTPUT cathode line

drv_7seg_S1:    ; do nothing
    ld  ix, SEG_STATE
    inc (ix)
    jr  drv_7seg_end

drv_7seg_S2:    ; 7seg blanking
    xor a
    out (PO_1), a
;
    ld  ix, SEG_STATE
    ld (ix), S_SEG_0

drv_7seg_exit: ;;  inclease anode line number
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

out_PO_2:
    out (PO_2), a
                ; OUTPUT anode line
    ld  (PO_2_BUP), a
                ; BACKUP PO_2
;
    ret

;;
;;; 7seg subroutines
;;
drv_7seg_sub_disp4: ;; HL = disp. "  hhll", destroy AF
    push    bc
    push    hl
;
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
;
;   falldown to drv_7seg_sub_disp2_2
    jr  drv_7seg_sub_disp2_2

drv_7seg_sub_disp2: ;; A = disp. "    aa", destroy AF
    push    bc
    push    hl
drv_7seg_sub_disp2_2:
    ld  l, a
;
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
    pop hl
    pop bc
    ret

    include "../Z80proto_dbg.asm"
    include "../Z80proto_misc.asm"
    include "../ascii_misc.asm"
    include "../Z80proto_spi.asm"

SEG_TITLE_PROTO2:
    defb    11001110b   ;   P
    defb    00001010b   ;   r
    defb    00111010b   ;   o
    defb    00011110b   ;   t
    defb    00111010b   ;   o
    defb    11011010b   ;   2

SEG_TITLE_LOADER:
    defb    00011100b   ;   L
    defb    01111010b   ;   d
    defb    00001010b   ;   r
    defb    0           ;   blank
    defb    0           ;   blank
    defb    0           ;   blank

SEG_TITLE_CONS:
    defb    10011100b   ;   C
    defb    00111010b   ;   o
    defb    00101010b   ;   n
    defb    00000010b   ;   -
    defb    11111100b   ;   0
    defb    11111100b   ;   0

STR_loader_title:
    defm    "\x0D\x0A\x0D\x0A\x0D\x0AMiniLoader"
    defb    CR
    defb    LF
    defb    NULL

STR_loader_prompt:
    defm    ">>>"
    defb    NULL
