;; command_t.asm -- test memory, etc.
  include "../memmap.def"

  PUBLIC  test_mode
  PUBLIC  _BUF_SIO256
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
; Tnnnn : test memory area 0x0nnnn to 0x0EFFF
  ld  ix, BUF_CON
  inc ix
  call  p_ix2bc
  ld  ( _XYW_DestAddr ), bc

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
  djnz  _tm_ZeroFill_buf_2
  ;
  ret

  PUBLIC  _tm_Transfer_Dest
_tm_Transfer_Dest:
  push  hl
  push  de
  push  bc
  push  af
  ;
  ld  hl, _BUF_SIO256 + 3
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

if WITH_7SEG == 0
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
endif
