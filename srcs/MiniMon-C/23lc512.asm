;   23lc512.asm - 23LC512 test routines
;   (C)2024 yasunoxx▼Julia <yasunoxx gmail com>

; 23LC512 command
SPIRAM_MODE_BYTE    EQU 00000000b
SPIRAM_MODE_PAGE    EQU 01000000b
SPIRAM_MODE_BURST   EQU 10000000b
SPIRAM_CMD_WRMR     EQU 00000001b
SPIRAM_CMD_WRITE    EQU 00000010b
SPIRAM_CMD_READ     EQU 00000011b
SPIRAM_CMD_RDMR     EQU 00000101b
SPIRAM_CMD_RSTIO    EQU 11111111b

;;
loader_spi_loop:
    call    loader_spiram_init
    jr  loader_spi_loop2

loader_spiram_init: ; 23LC512 init
    ld  a, SPI_DEVID_Ch0
    ld  (SPI_SELD_DEV), a
    call    spi_dev_sel
;
    ld  a, SPIRAM_CMD_RSTIO
    call    spi_write_8bit
;
    call    spi_dev_unsel
;
;; enter a byte mode
    ld  a, SPI_DEVID_Ch0
    ld  (SPI_SELD_DEV), a
    call    spi_dev_sel
;
    ld  a, SPIRAM_CMD_WRMR
    call    spi_write_8bit
    ld  a, SPIRAM_MODE_BYTE
    call    spi_write_8bit
;
    call    spi_dev_unsel
;
    ret

loader_spi_loop2:
;; write
    ld  a, SPI_DEVID_Ch0
    ld  (SPI_SELD_DEV), a
    call    spi_dev_sel
;
    ld  a, SPIRAM_CMD_WRITE
    call    spi_write_8bit
    xor a   ;   Addr. MSB
    call    spi_write_8bit
    xor a   ;   Addr. LSB
    call    spi_write_8bit
    ld  a, (LOOP_SEQ)
    dec a
    ld  (LOOP_SEQ), a
    call    spi_write_8bit
;
    call    spi_dev_unsel
;
;; read
    ld  a, SPI_DEVID_Ch0
    ld  (SPI_SELD_DEV), a
    call    spi_dev_sel
;
    ld  a, SPIRAM_CMD_READ
    call    spi_write_8bit
    xor a   ;   Addr. MSB
    call    spi_write_8bit
    xor a   ;   Addr. LSB
    call    spi_write_8bit
    call    spi_read_8bit
;
    push    af
    call    spi_dev_unsel
    pop af
;
;; disp readdata
    call    drv_7seg_sub_disp2
;; wait
    ld  bc, 0765h
    call    sloop
;
    jr  loader_spi_loop2
