;; command_x.asm -- handler, call xymodem.c functions
  include "../memmap.def"

  PUBLIC  receive_xymodem
  PUBLIC  _Transfer_Dest_xymodem
	PUBLIC	_SlowTick
  PUBLIC  _BUF_SIO128_0
  PUBLIC  _BUF_SIO128_1
  PUBLIC  _XYW
  PUBLIC  _BUF_GETCHAR_SIO0
  EXTERN  p_ix2bc
  EXTERN  _xymodem_main
  EXTERN  putchar_SIO0
  EXTERN  putCRLF
  EXTERN  putAreg2chrs
  EXTERN  loader_cons_oneliner

receive_xymodem:
; Xnnnn : receive X/YMODEM protocol, store to 0x0nnnn
  ld  ix, BUF_CON
  inc ix
  call  p_ix2bc
  ld( _XYW_DestAddr ), bc

  call  _xymodem_main
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
