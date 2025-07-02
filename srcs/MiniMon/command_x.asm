;; command_x.asm -- handler, call xymodem.c functions
  include "../memmap.def"

  PUBLIC  receive_xymodem
  PUBLIC  _Transfer_Dest_xymodem
	PUBLIC	_SysTick
	PUBLIC	_SlowTick
  PUBLIC  _BUF_SIO128_0
  PUBLIC  _BUF_SIO128_1
  PUBLIC  _XYW
  PUBLIC  _BUF_GETCHAR_SIO0
  EXTERN  p_ix2bc
;  EXTERN  _xymodem_main
  EXTERN  getchar_SIO0
  EXTERN  putchar_SIO0
  EXTERN  putCRLF
  EXTERN  putAreg2chrs
  EXTERN  _LCD_Init
  EXTERN  _LCD_PutChar
  EXTERN  loader_cons_oneliner
;;  EXTERN  _D_clrCount
;;  EXTERN  _D_incCount
;;  EXTERN  _D_dispCount

receive_xymodem:
; Xnnnn : receive X/YMODEM protocol, store to 0x0nnnn
;;  call  _LCD_Init
;;  call  _D_clrCount
;;  call  _D_dispCount
  ld  ix, BUF_CON
  inc ix
  call  p_ix2bc
  ld  ( _XYW_DestAddr ), bc

;  call  _xymodem_main
  call  xymodem_main
  ; HL = return value
  call  putCRLF
  ld  l, a
  call  putAreg2chrs
  call  putCRLF

  jp  loader_cons_oneliner

_Transfer_Dest_xymodem:
  push  hl
  push  de
  push  bc
  push  af
  ;
  ld  hl, _BUF_SIO128_0
  ld  de, ( _XYW_DestAddr )
  ld  bc, 128
  ldir
  ;
  ld  ( _XYW_DestAddr ), de
  ;
  pop af
  pop bc
  pop de
  pop hl

  ret

xymodem_main:
  defc NUL = 0
  defc SOH = 1
  defc STX = 2
  defc EOT = 4
  defc ACK = 6
  defc NAK = 0x15
  defc CAN = 0x18
  defc CHR_C =  0x43
  defc SPC = 32
  defc CPMEOF = 28
  defc CR  = 13
  defc LF  = 11
  defc DEL = 127
  defc  false = 0
  defc  true = 1

  ;; strategy: SOH only, read x bytes(except NORECV) w/timeout
  ; put 'C'
  ld  a, false
  ld  (_XYW+9), a   ; A -> XYW.F_firstack
  ld  a, 'C'
  call putchar_SIO0
xymodem_main_2:
;;  call  _D_clrCount
  call  xymodem_getchar_SIO
  ld  a, (BUF_GETCHAR_SIO0+1)
  cp 0FFh
  jr  nz, xymodem_main_SOH
    ; timeout
    ld  a, (_XYW+9)   ; XYW.F_firstack -> A
    cp false
    jr  z, xymodem_main ; restart
      call  xymodem_main_nak
      jr  xymodem_main_2  ;

xymodem_main_SOH:
  ; caught any char.
  ld  a, (BUF_GETCHAR_SIO0)
  cp STX
  jr  nz, xymodem_main_SOH_2
    ; STX -> NAK
    call xymodem_main_flush_nak
    jr  xymodem_main_2
xymodem_main_SOH_2:
  cp EOT
    ; EOT -> ACK
    jp  z, xymodem_main_eot
xymodem_main_SOH_3:
  cp SOH
  ; SOH -> SEQ
  jr  z, xymodem_main_SEQ

  ; invalid header ?
  call xymodem_main_flush_nak
  ld  a, (_XYW+9)   ; XYW.F_firstack -> A
  cp false
    jr  z, xymodem_main ; restart
    jr  xymodem_main_2  ;

xymodem_main_SEQ:
  ; catch Data
  ld  ix, ( _BUF_SIO256 )
  ld  b, 132  ; SEQ, comp SEQ, Data[128], CRCH, CRCL
xymodem_main_FRAME:
  push  bc
  call  xymodem_getchar_SIO
  ld  a, (BUF_GETCHAR_SIO0+1)
  cp 0FFh
  jr  z, xymodem_main_FRAME_TOUT
  ;
  ld  a, (BUF_GETCHAR_SIO0)
  ld  (ix), a
  inc ix
;;  call  _D_incCount
  pop bc
  djnz  xymodem_main_FRAME
  ;

xymodem_main_FRAME_Check:
  ; SEQ & comp. SEQ
  ; CRCH, CRCL
  ; valid.
  ld de, ( _BUF_SIO256 + 2 )
  ld hl, ( _XYW_DestAddr )
  ld bc, 128  ; Data[128]
  ldir
  ld ( _XYW_DestAddr ), hl

xymodem_main_FRAME_end:
  ; Read succeed, send ack
  ld  a, ACK
  call  putchar_SIO0
  ld  a, true
  ld  (_XYW+9), a   ; A -> XYW.F_firstack
  ; read next frame
  jp xymodem_main_2

xymodem_main_FRAME_TOUT:
  pop bc
  call  xymodem_main_flush_nak ; NORECV timeout
;;  call  _D_dispCount
  jr  xymodem_main_FRAME_end

xymodem_main_eot:
  ; Read succeed, send ack
  ld  a, ACK
  call  putchar_SIO0
  ; exit
  ret

xymodem_main_flush_nak:
  ld  hl, 0
  ld  (SysTick2), hl
xymodem_main_flush_nak_2:
  call  xymodem_getchar_SIO
  ld  a, (BUF_GETCHAR_SIO0+1)
  cp 0FFh
  jr nz, xymodem_main_flush_nak
  ;
  ld  hl, (SysTick2)
  ld  de, 500  ; set timeout 500msec
  sbc hl, de
  jr c, xymodem_main_flush_nak_2
  ;
xymodem_main_nak:
  ld  a, NAK
  call  putchar_SIO0
  ret

xymodem_getchar_SIO:
  ; get char. with timeout
  ld  hl, 0
  ld  (SysTick), hl
xymodem_getchar_SIO_2:
  call  getchar_SIO0
  ld  a, (BUF_GETCHAR_SIO0+1)
  cp 0FFh
  ret nz  ; caught any char.
  ;
  ld  hl, (SysTick)
  ld  de, 500  ; set timeout 500msec
  sbc hl, de
  jr c, xymodem_getchar_SIO_2
  ; timeout
  ret
