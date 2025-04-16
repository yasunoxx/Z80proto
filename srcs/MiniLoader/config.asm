;   config.asm - configuration for m_loader.asm

;;  !CHOOSE ANY ONE!: interrupt mode IM2 or IM1
;  use im2
    DEFC INTERRUPT_MODE = 2
    im  2
;  use im1
;   DEFC INTERRUPT_MODE = 1
;    im  1


;;  !!!EDIT CAREFULLY!!!
    ld  sp, 0FFFFh


;   end config.asm
