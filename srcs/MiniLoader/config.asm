;   config.asm - configuration for m_loader.asm

;;  !CHOOSE ANY ONE!: interrupt mode IM2 or IM1
;  use im2
    DEFC INTERRUPT_MODE = 2
    im  2
;  use im1
;   DEFC INTERRUPT_MODE = 1
;    im  1

;; !CHOOSE ANY ONE!: Target type
;  use Z80proto2
;    DEFC TARGET_Z80PROTO = 2
;    DEFC SIO_RX_INT = 1
;  use Super AKI-80 with Support Module
    DEFC TARGET_SAKI80 = 1
    DEFC SUPMOD = 1
    DEFC SIO_RX_INT = 0
;  and use PPI(TMP82C265B) Chip 0 Port B
    DEFC DEBUG_PPIOUT = 1
    DEFC DEBUG_PPICTRL = 33h
    DEFC DEBUG_PPIPB = 31h
    PUBLIC  _DEBUG_PPIOUT_SETUP
;  use Super AKI-80 without Support Module, Normal AKI-80, Z84C01x
;    DEFC TARGET_Z84C01X = 1
;    DEFC SUPMOD = 0

;;  !!!EDIT CAREFULLY!!!
    ld  sp, 0FFFFh


;   end config.asm
