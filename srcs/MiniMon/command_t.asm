;; command_t.asm -- test memory, etc.
  include "../memmap.def"

  PUBLIC  test_mode
  PUBLIC  _BUF_SIO256
  PUBLIC  _SysTick
  PUBLIC  _TM
  EXTERN  p_ix2bc
  EXTERN  putchar_SIO0
  EXTERN  putCRLF
  EXTERN  putAreg2chrs
  EXTERN  _testmode_main
  EXTERN  loader_cons_oneliner

PPI0PA   EQU 30h
PPI0PB   EQU 31h
PPI0PC   EQU 32h
PPI0CTL  EQU 33h

test_mode:
; T : Async. FIFO test mode
  ld  ix, BUF_CON
  inc ix
  call  p_ix2bc
  ld  ( _TM_DestAddr ), bc

  ld  a, 0FFh
  out (PPI0PC), a
  ld  a, 10011010b  ; PA7~0 : Mode 0, Input (FIFO I/O)
                    ; PC7~4 : Input (RXF#, TXE#)
                    ; PB7~0 : Mode 0, Input (Not Used)
                    ; PC3~0 : Output (RD*, WR*, CS*)
  out (PPI0CTL), a

; Control Lines(SAKI80)
PC_RXF  EQU 6
PC_TXE  EQU 7
PC_RD   EQU 0
PC_WR   EQU 1
PC_CS   EQU 2

  ;
  ;
  call  _testmode_main
  ;
  ;

  jp  loader_cons_oneliner

;;
  PUBLIC  _tm_SetRead
_tm_SetRead:
  ld  a, 10011010b  ; PA7~0 : Mode 0, Input (FIFO I/O)
                    ; PC7~4 : Input (RXF#, TXE#)
                    ; PB7~0 : Mode 0, Input (Not Used)
                    ; PC3~0 : Output (RD*, WR*, CS*)
  out ( PPI0CTL ), a
  ret

  PUBLIC  _tm_SetWrite
_tm_SetWrite:
  ld  a, 10001010b  ; PA7~0 : Mode 0, Output (FIFO I/O)
                    ; PC7~4 : Input (RXF#, TXE#)
                    ; PB7~0 : Mode 0, Input (Not Used)
                    ; PC3~0 : Output (RD*, WR*, CS*)
  out ( PPI0CTL ), a
  ret

  PUBLIC  _tm_ZeroFill_buf
_tm_ZeroFill_buf:
  ld  b, 0
  ld  ix, _BUF_SIO256
  xor a
_tm_ZeroFill_buf_2:
  ld  ( ix ), a
  inc ix
  djnz  _tm_ZeroFill_buf_2
  ;
  ret

  PUBLIC  _tm_Transfer_Dest
_tm_Transfer_Dest:
  push  hl
  push  de
  push  bc
  ;
  ld  hl, _BUF_SIO256 + 3
  ld  de, ( _TM_DestAddr )
  ld  bc, 128
  ldir
  ;
  ld  ( _TM_DestAddr ), de
  ;
  pop bc
  pop de
  pop hl

  ret
