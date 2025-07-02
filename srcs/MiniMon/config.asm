;   config.asm - configuration for m_loader.asm

;;  !CHOOSE ANY ONE!: interrupt mode IM2 or IM1
;  use im2
    DEFC INTERRUPT_MODE = 2
    im  2
;  use im1
;   DEFC INTERRUPT_MODE = 1
;    im  1

    DEFC RUN_WITH_ROM = 0
    DEFC RUN_ON_RAM = 1
;;  !CHOOSE ANY ONE!: "run on ROM" or "run on RAM"
    DEFC RUN_MODE = RUN_WITH_ROM
;    DEFC RUN_MODE = RUN_ON_RAM
;
;

;; !CHOOSE ANY ONE!: Target type
;  use Z80proto2
;    DEFC TARGET_Z80PROTO = 2
;    DEFC SIO_RX_INT = 1
;  use Super AKI-80 with Support Module
    DEFC TARGET_SAKI80 = 1
    DEFC SUPMOD = 1
    DEFC SIO_RX_INT = 0
;  use Super AKI-80 without Support Module, Normal AKI-80, Z84C01x
;    DEFC TARGET_Z84C01X = 1
;    DEFC SUPMOD = 0
;    DEFC SIO_RX_INT = 0
;  and use PIO(internal Z80A-PIO) Chip 0 Port B
if USE_LCD
    DEFC DEBUG_PIOOUT = 1
    DEFC DEBUG_PIOCTRL = 1Dh
    DEFC DEBUG_PIOA = 1Ch
    PUBLIC  _DEBUG_PIOOUT_SETUP
    PUBLIC  _DEBUG_PIOOUT
    PUBLIC  _DEBUG_PIOA_DATA
endif

;;  !!!EDIT CAREFULLY!!!
    ld  sp, 0FFFFh


;   end config.asm
