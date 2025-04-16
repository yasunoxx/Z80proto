;; call_dummy.asm -- handler, call dummy.c functions

    PUBLIC  call_dummy
    EXTERN  _dummy
    EXTERN  _sprit_buf
call_dummy:
    call    _dummy
    ; HL = return value(void *)
    call    _sprit_buf
