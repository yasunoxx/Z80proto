;;  Z80proto_spi.asm -- SPI routines for Z80proto
    PUBLIC  spi_dev_sel
    PUBLIC  spi_dev_unsel
    PUBLIC  spi_read_8bit
    PUBLIC  spi_write_8bit
;;
;;; SPI routines
;;
SCLK    EQU 3
MISO    EQU 4
MOSI    EQU 4

;;
spi_dev_sel:
    push    bc
;
    ld  a, (SPI_SELD_DEV)
    ld  c, a
;
    in  a, (PI_0)
    and 00000011b
    or  c
    OUT (PO_0), a
;
    pop bc
    ret

;;
spi_dev_unsel:
    ld  a, SPI_DEVID_NULL
    ld  (SPI_SELD_DEV), a
    jr  spi_dev_sel

;;
spi_read_8bit:
    call    spi_dev_sel
;
    push    bc
    push    de
;
;;  read sequence
    ld  b, 8
    ld  e, 0
;
spi_read_8bit_2:
    sla e
;;  clock 'H'
;;  A reg = (PI_0) AND 00000011b OR SPI_SELD_DEV
    set SCLK, a
    out (PO_0), a
    ld  c, a
;
;;  read MISO
    in  a, (PI_0)
    bit MISO, a
    jr  z, spi_read_8bit_L
spi_read_8bit_H:
    set 0, e
    jr  spi_read_8bit_3
spi_read_8bit_L:
    res 0, e
;;
spi_read_8bit_3:
    ld  a, c ;; clock 'L'
    res SCLK, a
    out (PO_0), a
;
;;  repeat
    djnz    spi_read_8bit_2
;
spi_read_8bit_end:
    ld  a, e
;
    pop de
    pop bc
;
    ret

;;
spi_write_8bit:
    push    de
    ld  e, a
;
    call    spi_dev_sel
;
    push    af
    push    bc
;
;;  write sequence
    ld  b, 8
spi_write_8bit_2: ;;  write MOSI
    bit 7, e
    jr  z, spi_write_8bit_L
spi_write_8bit_H:
    set MOSI, a
    jr  spi_write_8bit_3
spi_write_8bit_L:
    res MOSI, a
;;  
spi_write_8bit_3:
    out (PO_0), a
;;  clock 'H'
;;  A reg = (PI_0) AND 00000011b OR SPI_SELD_DEV
    set SCLK, a
;
    out (PO_0), a
;
;;  clock 'L'
    res SCLK, a
    out (PO_0), a
;;  repeat
    sla e
    djnz    spi_write_8bit_2
;
spi_write_8bit_end:
    pop bc
    pop af
    pop de
;
    ret

spi_read_16bit:
spi_write_16bit:
    ret
