FYI: WTF is this output !?
==========================

in xymodem.c:#344
    :
    :
    while( 1 )
    {
        register int16_t tbuf = get_SIO0_polling();
        if( tbuf <= 0x0FF )
        {
            :
            :

output(m_loader.lst)
i_49:
    call    _get_SIO0_polling               ;[0f43] cd 3e 0d
    push    hl                              ;[0f46] e5
    ld      de,$00ff                        ;[0f47] 11 ff 00
    ex      de,hl                           ;[0f4a] eb
    call    l_le                            ;[0f4b] cd ad 16
    jp      nc,i_51                         ;[0f4e] d2 ed 0f
    ld      hl,$0009                        ;[0f51] 21 09 00
    ;          ^^^^^ ?!?!?!?!
    add     hl,sp                           ;[0f54] 39
    ld      a,(hl)                          ;[0f55] 7e
    inc     hl                              ;[0f56] 23
    ld      h,(hl)                          ;[0f57] 66
    ld      l,a                             ;[0f58] 6f

(C)2025 yasunoxx▼Julia, this text is public domain .
