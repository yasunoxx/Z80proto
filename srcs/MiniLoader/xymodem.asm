;--------------------------------------------------------
; File Created by SDCC : free open source ANSI-C Compiler
; Version 4.0.0 #11528 (Linux)
;--------------------------------------------------------
	.module xymodem
	.optsdcc -mz80
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _get_SIO0_polling
	.globl _xymodem_main
	.globl _LCD_Puts
	.globl _LCD_Write
	.globl _LCD_Init
	.globl _puts_SIO0
	.globl _putchar_SIO0
	.globl _getchar_SIO0
	.globl _Transfer_Dest_xymodem
	.globl __NOP
	.globl _sprintf
	.globl _xymodem_init
	.globl _xymodem_receive
	.globl _xymodem_chkcrc
	.globl _updcrc
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _DATA
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _INITIALIZED
;--------------------------------------------------------
; absolute external ram data
;--------------------------------------------------------
	.area _DABS (ABS)
;--------------------------------------------------------
; global & static initialisations
;--------------------------------------------------------
	.area _HOME
	.area _GSINIT
	.area _GSFINAL
	.area _GSINIT
;--------------------------------------------------------
; Home
;--------------------------------------------------------
	.area _HOME
	.area _HOME
;--------------------------------------------------------
; code
;--------------------------------------------------------
	.area _CODE
;xymodem.c:63: void _NOP()
;	---------------------------------
; Function _NOP
; ---------------------------------
__NOP::
;xymodem.c:67: __endasm;
	nop
;xymodem.c:68: }
	ret
;xymodem.c:97: uint8_t xymodem_main()
;	---------------------------------
; Function xymodem_main
; ---------------------------------
_xymodem_main::
	call	___sdcc_enter_ix
	push	af
;xymodem.c:102: LCD_Init();
	call	_LCD_Init
;xymodem.c:103: LCD_Clear();
	ld	a, #0x01
	push	af
	inc	sp
	xor	a, a
	push	af
	inc	sp
	call	_LCD_Write
;xymodem.c:106: xsprintf( ( char * )cbuf, "xymodem.c, send anything\r\n" );
	ld	hl, #___str_0
	ex	(sp),hl
	ld	hl, #_BUF_SIO128_1
	push	hl
	call	_sprintf
	pop	af
;xymodem.c:107: puts_SIO0( cbuf );
	ld	hl, #_BUF_SIO128_1
	ex	(sp),hl
	call	_puts_SIO0
	pop	af
;xymodem.c:109: xymodem_init();
	call	_xymodem_init
;xymodem.c:110: while( 1 )
00114$:
;xymodem.c:112: result = xymodem_receive( SECOND * 2 );   // wait initpkt
	ld	hl, #0x0004
	push	hl
	call	_xymodem_receive
	pop	af
;xymodem.c:113: switch( result )
	ld	-1 (ix), l
	ld	a, l
	sub	a, #0x04
	jp	Z,00104$
	ld	a, -1 (ix)
	sub	a, #0x06
	jp	NZ,00108$
;xymodem.c:119: LCD_SetCursorPos( 0, 1 );
	ld	a, #0xc0
	push	af
	inc	sp
	xor	a, a
	push	af
	inc	sp
	call	_LCD_Write
;xymodem.c:120: LCD_Puts( ( uint8_t * )"R/ACK", 16 );
	ld	h,#0x10
	ex	(sp),hl
	inc	sp
	ld	hl, #___str_1
	push	hl
	call	_LCD_Puts
	pop	af
	inc	sp
;xymodem.c:121: LCD_SetCursorPos( 6, 1 );
	ld	a, #0xc6
	push	af
	inc	sp
	xor	a, a
	push	af
	inc	sp
	call	_LCD_Write
	pop	af
;xymodem.c:123: "%04X=%02X:%02X", XYW.CRC, XYW.CRCH, XYW.CRCL );
	ld	a, (#(_XYW + 0x0004) + 0)
	ld	-2 (ix), a
	xor	a, a
	ld	-1 (ix), a
	ld	a, (#(_XYW + 0x0003) + 0)
	ld	e, a
	ld	d, #0x00
	ld	bc, (#(_XYW + 0x0005) + 0)
;xymodem.c:122: xsprintf( ( char * )cbuf,
	pop	hl
	push	hl
	push	hl
	push	de
	push	bc
	ld	hl, #___str_2
	push	hl
	ld	hl, #_BUF_SIO128_1
	push	hl
	call	_sprintf
	ld	hl, #10
	add	hl, sp
	ld	sp, hl
;xymodem.c:124: LCD_Puts( cbuf, 10 );
	ld	a, #0x0a
	push	af
	inc	sp
	ld	hl, #_BUF_SIO128_1
	push	hl
	call	_LCD_Puts
	pop	af
	inc	sp
;xymodem.c:127: if( XYW.F_firstack == true )
	ld	a, (#(_XYW + 0x0009) + 0)
	dec	a
	jr	NZ,00103$
;xymodem.c:133: Transfer_Dest_xymodem();
	call	_Transfer_Dest_xymodem
;xymodem.c:137: LCD_SetCursorPos( 4, 0 );
	ld	a, #0x84
	push	af
	inc	sp
	xor	a, a
	push	af
	inc	sp
	call	_LCD_Write
	pop	af
;xymodem.c:138: xsprintf( ( char * )cbuf, "0x%08X", XYW.DestAddr );
	ld	bc, (#_XYW + 0)
	push	bc
	ld	hl, #___str_3
	push	hl
	ld	hl, #_BUF_SIO128_1
	push	hl
	call	_sprintf
	pop	af
	pop	af
;xymodem.c:139: LCD_Puts( cbuf, 10 );
	ld	h,#0x0a
	ex	(sp),hl
	inc	sp
	ld	hl, #_BUF_SIO128_1
	push	hl
	call	_LCD_Puts
	pop	af
	inc	sp
00103$:
;xymodem.c:143: XYW.Serial--;
	ld	bc, #_XYW+2
	ld	a, (bc)
	dec	a
	ld	(bc), a
;xymodem.c:144: XYW.S_xymodem_state = SEQACK;
	ld	hl, #(_XYW + 0x0007)
	ld	(hl), #0x02
;xymodem.c:145: break;
	jp	00114$
;xymodem.c:146: case EOT:
00104$:
;xymodem.c:149: LCD_SetCursorPos( 0, 1 );
	ld	a, #0xc0
	push	af
	inc	sp
	xor	a, a
	push	af
	inc	sp
	call	_LCD_Write
;xymodem.c:150: LCD_Puts( ( uint8_t * )"R/EOT", 16 );
	ld	h,#0x10
	ex	(sp),hl
	inc	sp
	ld	hl, #___str_4
	push	hl
	call	_LCD_Puts
	pop	af
	inc	sp
;xymodem.c:153: if( XYW.S_xymodem_EOTstate >= 2 )
	ld	a, (#(_XYW + 0x0008) + 0)
	sub	a, #0x02
	jp	C, 00114$
;xymodem.c:156: return 0;
	ld	l, #0x00
	jr	00116$
;xymodem.c:160: default:
00108$:
;xymodem.c:163: LCD_SetCursorPos( 0, 1 );
	ld	a, #0xc0
	push	af
	inc	sp
	xor	a, a
	push	af
	inc	sp
	call	_LCD_Write
;xymodem.c:164: LCD_Puts( ( uint8_t * )"R/NAK", 16 );
	ld	h,#0x10
	ex	(sp),hl
	inc	sp
	ld	hl, #___str_5
	push	hl
	call	_LCD_Puts
	pop	af
	inc	sp
;xymodem.c:167: if( XYW.F_firstack == false )
	ld	a, (#(_XYW + 0x0009) + 0)
	or	a, a
	jr	NZ,00110$
;xymodem.c:170: xymodem_init();
	call	_xymodem_init
	jp	00114$
00110$:
;xymodem.c:179: XYW.S_xymodem_state = SEQNAK;
	ld	hl, #(_XYW + 0x0007)
	ld	(hl), #0x01
;xymodem.c:183: }
	jp	00114$
00116$:
;xymodem.c:185: }
	pop	af
	pop	ix
	ret
___str_0:
	.ascii "xymodem.c, send anything"
	.db 0x0d
	.db 0x0a
	.db 0x00
___str_1:
	.ascii "R/ACK"
	.db 0x00
___str_2:
	.ascii "%04X=%02X:%02X"
	.db 0x00
___str_3:
	.ascii "0x%08X"
	.db 0x00
___str_4:
	.ascii "R/EOT"
	.db 0x00
___str_5:
	.ascii "R/NAK"
	.db 0x00
;xymodem.c:187: void xymodem_init()
;	---------------------------------
; Function xymodem_init
; ---------------------------------
_xymodem_init::
;xymodem.c:189: XYW.CRC = 0;
	ld	hl, #0x0000
	ld	((_XYW + 0x0005)), hl
;xymodem.c:190: XYW.Serial = 0x0FF;
	ld	hl, #(_XYW + 0x0002)
	ld	(hl), #0xff
;xymodem.c:191: XYW.S_xymodem_state = 0; XYW.F_firstack = false;
	ld	hl, #(_XYW + 0x0007)
	ld	(hl), #0x00
	ld	hl, #(_XYW + 0x0009)
	ld	(hl), #0x00
;xymodem.c:192: XYW.S_xymodem_EOTstate = 0;
	ld	hl, #(_XYW + 0x0008)
	ld	(hl), #0x00
;xymodem.c:193: }
	ret
;xymodem.c:212: uint8_t get_SIO0_polling( void )
;	---------------------------------
; Function get_SIO0_polling
; ---------------------------------
_get_SIO0_polling::
;xymodem.c:215: while( 1 )
00109$:
;xymodem.c:217: tbuf = ( int16_t )getchar_SIO0();
	call	_getchar_SIO0
;xymodem.c:218: if( tbuf == 0 ) // NUL
	ld	a, h
	or	a, l
	jr	NZ,00106$
;xymodem.c:220: tbuf = BUF_GETCHAR_SIO0;
	ld	hl, (_BUF_GETCHAR_SIO0)
;xymodem.c:221: if( tbuf == 0 ) // real NUL
	ld	a, h
;xymodem.c:223: return ( uint8_t )NUL;
	or	a,l
	jr	NZ,00109$
	ld	l,a
	ret
00106$:
;xymodem.c:226: else if( tbuf > 0 )
	xor	a, a
	cp	a, l
	sbc	a, h
	jp	PO, 00133$
	xor	a, #0x80
00133$:
	jp	P, 00109$
;xymodem.c:228: return ( uint8_t )NUL;
	ld	l, #0x00
;xymodem.c:231: }
	ret
;xymodem.c:235: uint8_t xymodem_receive( uint16_t wait )
;	---------------------------------
; Function xymodem_receive
; ---------------------------------
_xymodem_receive::
	call	___sdcc_enter_ix
	push	af
	push	af
	push	af
;xymodem.c:238: register uint16_t count = 0, limit, prevTick;
	ld	bc, #0x0000
;xymodem.c:242: switch( XYW.S_xymodem_state )
	ld	a, (#(_XYW + 0x0007) + 0)
	or	a, a
	jr	Z,00101$
	cp	a, #0x01
	jr	Z,00102$
	cp	a, #0x02
	jr	Z,00103$
	sub	a, #0x03
	jr	Z,00106$
	jr	00108$
;xymodem.c:244: case SEQSTART:
00101$:
;xymodem.c:246: xymodem_startpkt();
	push	bc
	ld	a, #0x43
	push	af
	inc	sp
	call	_putchar_SIO0
	inc	sp
	pop	bc
;xymodem.c:247: XYW.S_xymodem_state = SEQACK;
	ld	hl, #(_XYW + 0x0007)
	ld	(hl), #0x02
;xymodem.c:248: break;
	jr	00108$
;xymodem.c:249: case SEQNAK:
00102$:
;xymodem.c:251: xymodem_sendnak();
	push	bc
	ld	a, #0x15
	push	af
	inc	sp
	call	_putchar_SIO0
	inc	sp
	pop	bc
;xymodem.c:253: XYW.S_xymodem_state = SEQACK;
	ld	hl, #(_XYW + 0x0007)
	ld	(hl), #0x02
;xymodem.c:254: break;
	jr	00108$
;xymodem.c:255: case SEQACK:
00103$:
;xymodem.c:257: xymodem_sendack();
	push	bc
	ld	a, #0x06
	push	af
	inc	sp
	call	_putchar_SIO0
	inc	sp
	pop	bc
;xymodem.c:258: if( XYW.F_firstack == false )
	ld	a, (#(_XYW + 0x0009) + 0)
	or	a, a
	jr	NZ,00105$
;xymodem.c:260: XYW.F_firstack = true;
	ld	hl, #(_XYW + 0x0009)
	ld	(hl), #0x01
00105$:
;xymodem.c:262: XYW.S_xymodem_state = SEQACK;
	ld	hl, #(_XYW + 0x0007)
	ld	(hl), #0x02
;xymodem.c:263: break;
	jr	00108$
;xymodem.c:264: case SEQEOT:
00106$:
;xymodem.c:267: XYW.S_xymodem_state = SEQEOT;
	ld	hl, #(_XYW + 0x0007)
	ld	(hl), #0x03
;xymodem.c:270: }
00108$:
;xymodem.c:272: prevTick = SlowTick;
	ld	hl, (_SlowTick)
	ex	(sp), hl
;xymodem.c:273: while( 1 )
	ld	a, -6 (ix)
	add	a, 4 (ix)
	ld	-4 (ix), a
	ld	a, -5 (ix)
	adc	a, 5 (ix)
	ld	-3 (ix), a
00114$:
;xymodem.c:283: getchar_SIO0();
	push	bc
	call	_getchar_SIO0
	pop	bc
;xymodem.c:284: register uint16_t tbuf = BUF_GETCHAR_SIO0;
	ld	hl, (_BUF_GETCHAR_SIO0)
	ld	-2 (ix), l
;xymodem.c:285: if( ( tbuf & 0x00FF00 ) == 0 )
	ld	-1 (ix), h
	ld	a, h
	or	a, a
	jr	NZ,00110$
;xymodem.c:287: buf = ( uint8_t )tbuf;
	ld	a, -2 (ix)
	ld	-4 (ix), a
;xymodem.c:288: break;
	jr	00115$
00110$:
;xymodem.c:291: if( SlowTick > prevTick + wait )
	ld	a, -4 (ix)
	ld	iy, #_SlowTick
	sub	a, 0 (iy)
	ld	a, -3 (ix)
	sbc	a, 1 (iy)
	jr	NC,00114$
;xymodem.c:293: return NAK;
	ld	l, #0x15
	jp	00141$
00115$:
;xymodem.c:297: switch( buf )
	ld	a, -4 (ix)
	dec	a
	jr	Z,00116$
	ld	a, -4 (ix)
	sub	a, #0x02
	jr	Z,00117$
	ld	a, -4 (ix)
	sub	a, #0x04
	jr	Z,00118$
	jr	00124$
;xymodem.c:299: case SOH:
00116$:
;xymodem.c:300: limit = 128;
	ld	de, #0x0080
;xymodem.c:301: break;
	jr	00125$
;xymodem.c:302: case STX:
00117$:
;xymodem.c:303: limit = 1024;
	ld	de, #0x0400
;xymodem.c:304: break;
	jr	00125$
;xymodem.c:306: case EOT:
00118$:
;xymodem.c:307: XYW.S_xymodem_state = SEQEOT;
	ld	hl, #(_XYW + 0x0007)
	ld	(hl), #0x03
;xymodem.c:308: switch( XYW.S_xymodem_EOTstate )
	ld	a, (#(_XYW + 0x0008) + 0)
	or	a, a
	jr	Z,00122$
	cp	a, #0x01
	jr	Z,00119$
	sub	a, #0x02
	jr	Z,00120$
	jr	00122$
;xymodem.c:310: case 1:
00119$:
;xymodem.c:311: xymodem_sendack();
	ld	a, #0x06
	push	af
	inc	sp
	call	_putchar_SIO0
	inc	sp
;xymodem.c:312: xymodem_startpkt();
	ld	a, #0x43
	push	af
	inc	sp
	call	_putchar_SIO0
	inc	sp
;xymodem.c:313: XYW.S_xymodem_EOTstate = 2;
	ld	hl, #(_XYW + 0x0008)
	ld	(hl), #0x02
;xymodem.c:314: return EOT;
	ld	l, #0x04
	jp	00141$
;xymodem.c:315: case 2:
00120$:
;xymodem.c:317: xymodem_sendack();
	ld	a, #0x06
	push	af
	inc	sp
	call	_putchar_SIO0
	inc	sp
;xymodem.c:318: XYW.S_xymodem_EOTstate = 3;
	ld	hl, #(_XYW + 0x0008)
	ld	(hl), #0x03
;xymodem.c:319: return EOT;
	ld	l, #0x04
	jp	00141$
;xymodem.c:321: default:
00122$:
;xymodem.c:322: xymodem_sendnak();
	ld	a, #0x15
	push	af
	inc	sp
	call	_putchar_SIO0
	inc	sp
;xymodem.c:323: XYW.S_xymodem_EOTstate = 1;
	ld	hl, #(_XYW + 0x0008)
	ld	(hl), #0x01
;xymodem.c:324: return EOT;
	ld	l, #0x04
	jp	00141$
;xymodem.c:327: default:
00124$:
;xymodem.c:328: return NAK;
	ld	l, #0x15
	jp	00141$
;xymodem.c:329: }
00125$:
;xymodem.c:332: LCD_SetCursorPos( 0, 0 );
	push	bc
	push	de
	ld	a, #0x80
	push	af
	inc	sp
	xor	a, a
	push	af
	inc	sp
	call	_LCD_Write
	pop	af
	pop	de
	pop	bc
;xymodem.c:333: xsprintf( ( char * )cbuf, ( const char * )"%02X->%4d", buf, limit );
	ld	a, -4 (ix)
	ld	-2 (ix), a
	xor	a, a
	ld	-1 (ix), a
	push	bc
	push	de
	ld	l, -2 (ix)
	ld	h, -1 (ix)
	push	hl
	ld	hl, #___str_6
	push	hl
	ld	hl, #_BUF_SIO128_1
	push	hl
	call	_sprintf
	pop	af
	pop	af
	pop	af
	ld	h,#0x0c
	ex	(sp),hl
	inc	sp
	ld	hl, #_BUF_SIO128_1
	push	hl
	call	_LCD_Puts
	pop	af
	inc	sp
	ld	a, #0x88
	push	af
	inc	sp
	xor	a, a
	push	af
	inc	sp
	call	_LCD_Write
	pop	af
	pop	bc
;xymodem.c:338: if( buf == STX ) return NAK;
	ld	a, -4 (ix)
	sub	a, #0x02
	jr	NZ,00162$
	ld	l, #0x15
	jp	00141$
;xymodem.c:344: while( 1 )
00162$:
	ld	de, #0x0000
	ld	-1 (ix), #0x01
00139$:
;xymodem.c:346: register int16_t tbuf = get_SIO0_polling();
	push	bc
	push	de
	call	_get_SIO0_polling
	pop	de
	pop	bc
	ld	h, #0x00
;xymodem.c:347: if( tbuf <= 0x0FF )
	ld	a, #0xff
	cp	a, l
	ld	a, #0x00
	sbc	a, h
	jp	PO, 00262$
	xor	a, #0x80
00262$:
	jp	M, 00135$
;xymodem.c:349: switch( count )
	ld	-3 (ix), e
	ld	-2 (ix), d
	ld	a, -3 (ix)
	sub	a, #0x80
	or	a, -2 (ix)
	jr	Z,00128$
	ld	a, -3 (ix)
	sub	a, #0x81
	or	a, -2 (ix)
	jr	Z,00129$
	jr	00130$
;xymodem.c:351: case 128:
00128$:
;xymodem.c:352: _NOP();
	push	bc
	push	de
	call	__NOP
	pop	de
	pop	bc
;xymodem.c:353: XYW.CRCH = buf;
	ld	hl, #(_XYW + 0x0003)
	ld	a, -4 (ix)
	ld	(hl), a
;xymodem.c:354: break;
	jr	00131$
;xymodem.c:355: case 129:
00129$:
;xymodem.c:356: _NOP();
	call	__NOP
;xymodem.c:357: XYW.CRCL = buf; // receive succeed(maybe)
	ld	hl, #(_XYW + 0x0004)
	ld	a, -4 (ix)
	ld	(hl), a
;xymodem.c:361: xsprintf( ( char * )cbuf, ( const char * )"->%4d", count - 1 );
	ld	c, -3 (ix)
	ld	b, -2 (ix)
	dec	bc
	push	bc
	ld	hl, #___str_7
	push	hl
	ld	hl, #_BUF_SIO128_1
	push	hl
	call	_sprintf
	pop	af
	pop	af
;xymodem.c:362: LCD_Puts( cbuf, 6 );
	ld	h,#0x06
	ex	(sp),hl
	inc	sp
	ld	hl, #_BUF_SIO128_1
	push	hl
	call	_LCD_Puts
	pop	af
	inc	sp
;xymodem.c:365: return ACK;
	ld	l, #0x06
	jr	00141$
;xymodem.c:368: default:
00130$:
;xymodem.c:369: RxBuf[ count ] = buf;
	ld	hl, #_BUF_SIO128_0+0
	add	hl, de
	ld	a, -4 (ix)
	ld	(hl), a
;xymodem.c:371: }
00131$:
;xymodem.c:373: preCount++;
	inc	-1 (ix)
;xymodem.c:374: if( preCount > 2 )  // ignore head(3bytes)
	ld	a, #0x02
	sub	a, -1 (ix)
	jr	NC,00133$
;xymodem.c:376: count++;
	inc	de
	ld	c, e
	ld	b, d
00133$:
;xymodem.c:378: prevTick = SlowTick;
	ld	hl, (_SlowTick)
	ex	(sp), hl
00135$:
;xymodem.c:380: if( SlowTick > prevTick + wait )
	ld	a, -6 (ix)
	add	a, 4 (ix)
	ld	-3 (ix), a
	ld	a, -5 (ix)
	adc	a, 5 (ix)
	ld	-2 (ix), a
	ld	a, -3 (ix)
	ld	iy, #_SlowTick
	sub	a, 0 (iy)
	ld	a, -2 (ix)
	sbc	a, 1 (iy)
	jp	NC, 00139$
;xymodem.c:384: xsprintf( ( char * )cbuf, ( const char * )"-X%4d", count );
	push	bc
	ld	hl, #___str_8
	push	hl
	ld	hl, #_BUF_SIO128_1
	push	hl
	call	_sprintf
	pop	af
	pop	af
;xymodem.c:385: LCD_Puts( cbuf, 6 );
	ld	h,#0x06
	ex	(sp),hl
	inc	sp
	ld	hl, #_BUF_SIO128_1
	push	hl
	call	_LCD_Puts
	pop	af
	inc	sp
;xymodem.c:388: return NAK;
	ld	l, #0x15
00141$:
;xymodem.c:391: }
	ld	sp, ix
	pop	ix
	ret
___str_6:
	.ascii "%02X->%4d"
	.db 0x00
___str_7:
	.ascii "->%4d"
	.db 0x00
___str_8:
	.ascii "-X%4d"
	.db 0x00
;xymodem.c:393: bool xymodem_chkcrc()
;	---------------------------------
; Function xymodem_chkcrc
; ---------------------------------
_xymodem_chkcrc::
;xymodem.c:395: if( XYW.CRC == ( XYW.CRCH << 8 ) + XYW.CRCL )
	ld	bc, (#(_XYW + 0x0005) + 0)
	ld	a, (#(_XYW + 0x0003) + 0)
	ld	d, a
	ld	e, #0x00
	ld	a, (#(_XYW + 0x0004) + 0)
	ld	l, a
	ld	h, #0x00
	add	hl, de
	ex	de, hl
	ex	de,hl
	cp	a, a
	sbc	hl, bc
;xymodem.c:397: return true;
;xymodem.c:399: return false;
	ld	l, #0x01
	ret	Z
	ld	l, #0x00
;xymodem.c:400: }
	ret
;xymodem.c:402: uint16_t updcrc( uint16_t c )
;	---------------------------------
; Function updcrc
; ---------------------------------
_updcrc::
	call	___sdcc_enter_ix
;xymodem.c:406: for( count = 7 ; count >= 0; count-- )
00104$:
;xymodem.c:408: XYW.CRC <<= 1;
	ld	hl, (#(_XYW + 0x0005) + 0)
	add	hl, hl
	ld	c, l
	ld	b, h
	ld	((_XYW + 0x0005)), bc
;xymodem.c:409: XYW.CRC += ( ( ( c <<= 1 ) & 0400 ) != 0 );
	ld	bc, (#(_XYW + 0x0005) + 0)
	ld	l, 4 (ix)
	ld	h, 5 (ix)
	add	hl, hl
	ld	4 (ix), l
	ld	5 (ix), h
	ld	a, h
	ld	e, #0x00
	and	a, #0x01
	ld	d, a
	or	a, e
	sub	a,#0x01
	ld	a, #0x00
	rla
	xor	a, #0x01
	ld	l, a
	ld	h, #0x00
	add	hl, bc
	ex	de, hl
	ld	((_XYW + 0x0005)), de
;xymodem.c:410: if( XYW.CRC & 0x8000 )
	ld	hl, (#(_XYW + 0x0005) + 0)
	add	hl, hl
	jr	NC,00104$
;xymodem.c:412: XYW.CRC ^= 0x1021;
	ld	hl, (#(_XYW + 0x0005) + 0)
	ld	a, l
	xor	a, #0x21
	ld	c, a
	ld	a, h
	xor	a, #0x10
	ld	b, a
	ld	((_XYW + 0x0005)), bc
;xymodem.c:406: for( count = 7 ; count >= 0; count-- )
	jr	00104$
;xymodem.c:415: return XYW.CRC;
;xymodem.c:416: }
	pop	ix
	ret
	.area _CODE
	.area _INITIALIZER
	.area _CABS (ABS)
