;; command_k.asm -- handler, call kermit.c functions

    PUBLIC  receive_kermit
    EXTERN  _kermit_main
    EXTERN  putchar_SIO0
    EXTERN  putCRLF
    EXTERN  putAreg2chrs
    EXTERN  loader_cons_oneliner
receive_kermit:
    call    _kermit_main
    ; HL = return value(void *)
    call    putAreg2chrs

    jp  loader_cons_oneliner
