;; command_f.asm -- 'F' command implement, FDC/DMA subroutines for MiniMon
;
    include "../z80dma_fdc.def"
    include "../z80sioctc.def"
    include "../memmap.def"

    PUBLIC  fdc_command_cons
    EXTERN  STR_FDCDMA
    EXTERN  STR_error
    EXTERN  sloop
    EXTERN  loop
    EXTERN  puts_SIO0
    EXTERN  putchar_SIO0
    EXTERN  p_ix2bc

    ; MiniMon
    EXTERN  loader_cons_oneliner

    ; command_f.c
    EXTERN  _Command_F_getBuffer

fdc_command_cons:
; FFnnxx : write FDC register 'nn' to data 'xx'
; FDnnxx : write DMA register 'nn' to data 'xx'
; FOxx : write CONTROL port data 'xx'
; FI : read CONTROL port
    ld  ix, BUF_CON
    inc ix
    ld  a, (ix)
    push    af
    inc ix
    call    p_ix2bc
    ld  (FDC_COMMAND_DATA), bc  ; command & data
    pop af
;
    cp  'F'
;    jp  z, fdc_cmd_fdc
    cp  'D'
;    jp  z, fdc_cmd_dma
    cp  'O'
    jp  z, fdc_cmd_wctrl
    cp  'I'
    jp  z, fdc_cmd_rctrl
    ;
    ld  hl, STR_error
    call    puts_SIO0
    jp  fd_command_exit

fd_cmd_fdc:
    call    fd_init

fdc_cmd_wctrl:
;    ld  bc, (FDC_COMMAND_DATA)
    ld  a, (FDC_COMMAND_CMD)
    jr  fd_command_exit_2

fdc_cmd_rctrl:
    in  a, (FD_CONTROL)
    call    putAreg2chrs
    ld  a, CR
    call    putchar_SIO0
    ld  a, LF
    call    putchar_SIO0

fd_command_exit:
    xor a   ; MOTOR off, FDCRES* is 'L'
fd_command_exit_2:
    out (FD_CONTROL), a
    jp  loader_cons_oneliner


fd_init:
    call    _Command_F_getBuffer
    ld  iy, hl

; Stop Motor and check
    xor a   ; MOTOR off, FDCRES* is 'L', Drive 0, Side 0
    out (FD_CONTROL), a
;   wait 3000msec
;   check
    in  a, (FD_CONTROL)
    bit 7, a
    jr  z, fd_init_2
; MOTORON line trouble or FDC/DMA board not present ?
    ld  hl, STR_FDCDMA
    call    puts_SIO0
    ld  hl, STR_error
    call    puts_SIO0
    jp  fd_command_exit
;
fd_init_2:
;   FDC(and FDD) initialize
    xor a
    ; FDCRES* is 'H'
    set 5, a
    out (FD_CONTROL), a
    ; MOTORON is 'H', Drive 0
    set 0, a
    out (FD_CONTROL), a
    ; wait
    call    loop
    ; FDC initialize

    call    fd_wait_busy
    ; TRACK00
    ld  a, 02h
    out (FDC_CMD), a
    ; wait FDC busy
    call    fd_wait_busy
    ; MOTORON is 'L'
    res 5, a
    out (FD_CONTROL), a
    ; wait MOTOR off
fd_init_2_1:
    in  a, (FD_CONTROL)
    bit 7, a
    jr  nz, fd_init_2_1
fd_init_2_2:
    ret

fd_wait_busy:
    in  a, (FDC_CMD)
    and 81h
    jr  nz, fd_wait_busy
;
    ret

fd_wait_busy2:
    in  a, (FDC_CMD)
    push    af
    call    putAreg2chrs
    ld  a, LF
    call    putchar_SIO0
    pop af
    and 81h
    jr  nz, fd_wait_busy
;
    ld  a, CR
    call    putchar_SIO0
    ret

dma_init:
    ld b, 6
    ld  a, 0C6h
dma_init_2:
    out (DMA_CMD), a
    djnz    dma_init_2
;
    ret
