;; command_x.asm -- handler, call xymodem.c functions
    include "../memmap.def"

    PUBLIC  receive_xymodem
  	PUBLIC	_SlowTick
    PUBLIC  _BUF_SIO128_0
    PUBLIC  _BUF_SIO128_1
    PUBLIC  _XYW
    EXTERN  _xymodem_main
    EXTERN  putchar_SIO0
    EXTERN  putCRLF
    EXTERN  putAreg2chrs
    EXTERN  loader_cons_oneliner

receive_xymodem:
    call    _xymodem_main
    ; HL = return value(void *)
    call    putAreg2chrs

    jp  loader_cons_oneliner
