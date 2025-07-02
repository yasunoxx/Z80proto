;--------------------------------------------------------
; File Created by SDCC : free open source ANSI-C Compiler
; Version 4.0.0 #11528 (Linux)
;--------------------------------------------------------
	.module lcdlib
	.optsdcc -mz80
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _DEBUG_PIOOUT_SETUP
	.globl _DEBUG_PIOOUT
	.globl _LCD_Write
	.globl _LCD_Init
	.globl _LCD_PutChar
	.globl _LCD_Puts
	.globl _LCD_PutHex
	.globl _LCD_wait_msec
	.globl _LCD_ShiftDisp
	.globl _LCD_ShiftCursor
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
;lcdlib.c:100: void LCD_Write(unsigned char rs, unsigned char data) {
;	---------------------------------
; Function LCD_Write
; ---------------------------------
_LCD_Write::
;lcdlib.c:108: _lcd_wait_usec(100);
	ld	hl, #0x0064
	push	hl
	call	__lcd_wait_usec
	pop	af
;lcdlib.c:109: _lcd_write_no_busy_check(rs, (data >> 4));   /* write data high */
	ld	iy, #3
	add	iy, sp
	ld	a, 0 (iy)
	rlca
	rlca
	rlca
	rlca
	and	a, #0x0f
	push	af
	inc	sp
	dec	iy
	ld	a, 0 (iy)
	push	af
	inc	sp
	call	__lcd_write_no_busy_check
;lcdlib.c:110: _lcd_wait_usec(100);
	ld	hl, #0x0064
	ex	(sp),hl
	call	__lcd_wait_usec
	pop	af
;lcdlib.c:111: _lcd_write_no_busy_check(rs, (data & 0x0F)); /* write data low  */
	ld	iy, #3
	add	iy, sp
	ld	c, 0 (iy)
	ld	a, c
	and	a, #0x0f
	push	bc
	push	af
	inc	sp
	dec	iy
	ld	a, 0 (iy)
	push	af
	inc	sp
	call	__lcd_write_no_busy_check
	pop	af
	pop	bc
;lcdlib.c:114: if((rs==0) && (data < 0x04)) _lcd_wait_usec(1500);
	ld	hl, #2+0
	add	hl, sp
	ld	a, (hl)
	or	a, a
	ret	NZ
	ld	a, c
	sub	a, #0x04
	ret	NC
	ld	hl, #0x05dc
	push	hl
	call	__lcd_wait_usec
	pop	af
;lcdlib.c:115: }
	ret
;lcdlib.c:132: void LCD_Init(void) {
;	---------------------------------
; Function LCD_Init
; ---------------------------------
_LCD_Init::
;lcdlib.c:133: _lcd_init_hw_specific();
	call	__lcd_init_hw_specific
;lcdlib.c:135: _lcd_wait_usec(16000);            /* wait 16msec after POR   */
	ld	hl, #0x3e80
	push	hl
	call	__lcd_wait_usec
;lcdlib.c:136: _lcd_write_no_busy_check(0,0x03); /* Function Set: 0011      */
	ld	h,#0x03
	ex	(sp),hl
	inc	sp
	xor	a, a
	push	af
	inc	sp
	call	__lcd_write_no_busy_check
;lcdlib.c:137: _lcd_wait_usec(5000);             /* wait 5msec              */
	ld	hl, #0x1388
	ex	(sp),hl
	call	__lcd_wait_usec
;lcdlib.c:138: _lcd_write_no_busy_check(0,0x03); /* Function Set: 0011      */
	ld	h,#0x03
	ex	(sp),hl
	inc	sp
	xor	a, a
	push	af
	inc	sp
	call	__lcd_write_no_busy_check
;lcdlib.c:139: _lcd_wait_usec(150);              /* wait 150usec            */
	ld	hl, #0x0096
	ex	(sp),hl
	call	__lcd_wait_usec
;lcdlib.c:140: _lcd_write_no_busy_check(0,0x03); /* Function Set: 0011      */
	ld	h,#0x03
	ex	(sp),hl
	inc	sp
	xor	a, a
	push	af
	inc	sp
	call	__lcd_write_no_busy_check
;lcdlib.c:141: _lcd_wait_usec(100);
	ld	hl, #0x0064
	ex	(sp),hl
	call	__lcd_wait_usec
;lcdlib.c:144: _lcd_write_no_busy_check(0,0x02); /* Function Set: 4-bit mode */
	ld	h,#0x02
	ex	(sp),hl
	inc	sp
	xor	a, a
	push	af
	inc	sp
	call	__lcd_write_no_busy_check
;lcdlib.c:145: LCD_Write(0,0x28);  /* Function Set: 4-bit, 2-line      */
	ld	h,#0x28
	ex	(sp),hl
	inc	sp
	xor	a, a
	push	af
	inc	sp
	call	_LCD_Write
;lcdlib.c:146: LCD_Write(0,0x08);  /* Display=OFF                      */
	ld	h,#0x08
	ex	(sp),hl
	inc	sp
	xor	a, a
	push	af
	inc	sp
	call	_LCD_Write
;lcdlib.c:147: LCD_Write(0,0x01);  /* Display CLEAR                    */
	ld	h,#0x01
	ex	(sp),hl
	inc	sp
	xor	a, a
	push	af
	inc	sp
	call	_LCD_Write
;lcdlib.c:148: LCD_Write(0,0x06);  /* Entry Mode Set: Insert, No Shift */
	ld	h,#0x06
	ex	(sp),hl
	inc	sp
	xor	a, a
	push	af
	inc	sp
	call	_LCD_Write
;lcdlib.c:149: LCD_Write(0,0x0D);  /* Display=ON,Cursor=OFF, Blink=ON  */
	ld	h,#0x0d
	ex	(sp),hl
	inc	sp
	xor	a, a
	push	af
	inc	sp
	call	_LCD_Write
	pop	af
;lcdlib.c:150: }
	ret
;lcdlib.c:152: void LCD_PutChar(unsigned char c)
;	---------------------------------
; Function LCD_PutChar
; ---------------------------------
_LCD_PutChar::
;lcdlib.c:154: LCD_Putc(c);
	ld	hl, #2+0
	add	hl, sp
	ld	d, (hl)
	ld	e,#0x01
	push	de
	call	_LCD_Write
	pop	af
;lcdlib.c:155: }
	ret
;lcdlib.c:157: void LCD_Puts(unsigned char *buf, unsigned char maxlen)
;	---------------------------------
; Function LCD_Puts
; ---------------------------------
_LCD_Puts::
;lcdlib.c:160: while(maxlen > 0)
	ld	c, #0x00
	ld	hl, #4+0
	add	hl, sp
	ld	b, (hl)
00104$:
	ld	a, b
	or	a, a
	ret	Z
;lcdlib.c:162: if( buf[ ptr ] != '\0' )
	ld	iy, #2
	add	iy, sp
	ld	a, 0 (iy)
	add	a, c
	ld	e, a
	ld	a, 1 (iy)
	adc	a, #0x00
	ld	d, a
	ld	a, (de)
	or	a, a
	ret	Z
;lcdlib.c:164: LCD_Putc( buf[ ptr++ ] );
	inc	c
	push	bc
	ld	d,a
	ld	e,#0x01
	push	de
	call	_LCD_Write
	pop	af
	pop	bc
;lcdlib.c:165: maxlen--;
	dec	b
;lcdlib.c:169: break;
;lcdlib.c:172: }
	jr	00104$
;lcdlib.c:174: void LCD_PutHex(unsigned long n, signed char len)
;	---------------------------------
; Function LCD_PutHex
; ---------------------------------
_LCD_PutHex::
	call	___sdcc_enter_ix
;lcdlib.c:178: if (len > 8) len = 8;
	ld	a, #0x08
	sub	a, 8 (ix)
	jp	PO, 00131$
	xor	a, #0x80
00131$:
	jp	P, 00113$
	ld	8 (ix), #0x08
;lcdlib.c:179: while(len > 0) {
00113$:
	ld	c, 8 (ix)
00103$:
	xor	a, a
	sub	a, c
	jp	PO, 00132$
	xor	a, #0x80
00132$:
	jp	P, 00105$
;lcdlib.c:180: len--;
	dec	c
;lcdlib.c:181: c = ((unsigned char)(n>>(len*4))) & 0x0f;  /* c = (n >> (4*len)) & 0x0f; */
	ld	a, c
	add	a, a
	add	a, a
	ld	e, 4 (ix)
	ld	d, 5 (ix)
	ld	l, 6 (ix)
	ld	b, 7 (ix)
	inc	a
	jr	00134$
00133$:
	srl	b
	rr	l
	rr	d
	rr	e
00134$:
	dec	a
	jr	NZ, 00133$
	ld	a, e
	and	a, #0x0f
	ld	e, a
;lcdlib.c:182: c = (c > 9) ? (c + ('A'-10)) : (c + '0');
	ld	b, e
	ld	a, #0x09
	sub	a, e
	jr	NC,00108$
	ld	a, b
	add	a, #0x37
	jr	00109$
00108$:
	ld	a, b
	add	a, #0x30
00109$:
;lcdlib.c:183: LCD_Putc(c);
	push	bc
	ld	d,a
	ld	e,#0x01
	push	de
	call	_LCD_Write
	pop	af
	pop	bc
	jr	00103$
00105$:
;lcdlib.c:185: return;
;lcdlib.c:186: }
	pop	ix
	ret
;lcdlib.c:188: void LCD_wait_msec(unsigned short t)
;	---------------------------------
; Function LCD_wait_msec
; ---------------------------------
_LCD_wait_msec::
;lcdlib.c:190: while(t--){
	pop	de
	pop	bc
	push	bc
	push	de
00101$:
	ld	e, c
	ld	d, b
	dec	bc
	ld	a, d
	or	a, e
	ret	Z
;lcdlib.c:191: _lcd_wait_usec(1000);
	push	bc
	ld	hl, #0x03e8
	push	hl
	call	__lcd_wait_usec
	pop	af
	pop	bc
;lcdlib.c:193: return;
;lcdlib.c:194: }
	jr	00101$
;lcdlib.c:196: void LCD_ShiftDisp(signed int n)
;	---------------------------------
; Function LCD_ShiftDisp
; ---------------------------------
_LCD_ShiftDisp::
;lcdlib.c:199: while(n) {
	pop	de
	pop	bc
	push	bc
	push	de
;lcdlib.c:198: if (n>0) {
	xor	a, a
	ld	iy, #2
	add	iy, sp
	cp	a, 0 (iy)
	sbc	a, 1 (iy)
	jp	PO, 00144$
	xor	a, #0x80
00144$:
	jp	P, 00110$
;lcdlib.c:199: while(n) {
00101$:
	ld	a, b
	or	a, c
	ret	Z
;lcdlib.c:200: LCD_Write(0,0x1C); // Shift display to right
	push	bc
	ld	a, #0x1c
	push	af
	inc	sp
	xor	a, a
	push	af
	inc	sp
	call	_LCD_Write
	pop	af
	pop	bc
;lcdlib.c:201: n--;
	dec	bc
	jr	00101$
00110$:
;lcdlib.c:203: } else if (n<0) {
	ld	hl, #2+1
	add	hl, sp
	bit	7, (hl)
	ret	Z
;lcdlib.c:204: while(n) {
00104$:
	ld	a, b
	or	a, c
	ret	Z
;lcdlib.c:205: LCD_Write(0,0x18); // Shift display to left
	push	bc
	ld	a, #0x18
	push	af
	inc	sp
	xor	a, a
	push	af
	inc	sp
	call	_LCD_Write
	pop	af
	pop	bc
;lcdlib.c:206: n++;
	inc	bc
;lcdlib.c:209: }
	jr	00104$
;lcdlib.c:211: void LCD_ShiftCursor(signed int n)
;	---------------------------------
; Function LCD_ShiftCursor
; ---------------------------------
_LCD_ShiftCursor::
;lcdlib.c:214: while(n) {
	pop	de
	pop	bc
	push	bc
	push	de
;lcdlib.c:213: if (n>0) {
	xor	a, a
	ld	iy, #2
	add	iy, sp
	cp	a, 0 (iy)
	sbc	a, 1 (iy)
	jp	PO, 00144$
	xor	a, #0x80
00144$:
	jp	P, 00110$
;lcdlib.c:214: while(n) {
00101$:
	ld	a, b
	or	a, c
	ret	Z
;lcdlib.c:215: LCD_Write(0,0x14); // Move cursor to right
	push	bc
	ld	a, #0x14
	push	af
	inc	sp
	xor	a, a
	push	af
	inc	sp
	call	_LCD_Write
	pop	af
	pop	bc
;lcdlib.c:216: n--;
	dec	bc
	jr	00101$
00110$:
;lcdlib.c:218: } else if (n<0) {
	ld	hl, #2+1
	add	hl, sp
	bit	7, (hl)
	ret	Z
;lcdlib.c:219: while(n) {
00104$:
	ld	a, b
	or	a, c
	ret	Z
;lcdlib.c:220: LCD_Write(0,0x10); // Move cursor to left
	push	bc
	ld	a, #0x10
	push	af
	inc	sp
	xor	a, a
	push	af
	inc	sp
	call	_LCD_Write
	pop	af
	pop	bc
;lcdlib.c:221: n++;
	inc	bc
;lcdlib.c:224: }
	jr	00104$
;lcdlib.c:236: static void _lcd_wait_100ns(void)
;	---------------------------------
; Function _lcd_wait_100ns
; ---------------------------------
__lcd_wait_100ns:
;lcdlib.c:240: __endasm;
	nop	; 4sysclk = 500nsec@16MHz
;lcdlib.c:241: }
	ret
;lcdlib.c:245: static void _lcd_wait_300ns(void)
;	---------------------------------
; Function _lcd_wait_300ns
; ---------------------------------
__lcd_wait_300ns:
;lcdlib.c:249: __endasm;
	nop	; 4sysclk = 500nsec@16MHz
;lcdlib.c:250: }
	ret
;lcdlib.c:253: static void _lcd_wait_usec(unsigned int t)
;	---------------------------------
; Function _lcd_wait_usec
; ---------------------------------
__lcd_wait_usec:
	call	___sdcc_enter_ix
;lcdlib.c:257: i = t;
	ld	c, 4 (ix)
	ld	b, 5 (ix)
	ld	de, #0x0000
;lcdlib.c:258: i <<= 1;            /* t = t * 2; */
	sla	c
	rl	b
	rl	e
	rl	d
;lcdlib.c:259: while(i) {          /* 'while' takes ? cycles */
00101$:
	ld	a, d
	or	a, e
	or	a, b
	or	a, c
	jr	Z,00104$
;lcdlib.c:262: __endasm;
	nop	; 4sysclk = 500nsec@16MHz
;lcdlib.c:263: i--;            /* 'i--' takes ? cycle */
	ld	a, c
	add	a, #0xff
	ld	c, a
	ld	a, b
	adc	a, #0xff
	ld	b, a
	ld	a, e
	adc	a, #0xff
	ld	e, a
	ld	a, d
	adc	a, #0xff
	ld	d, a
	jr	00101$
00104$:
;lcdlib.c:265: }
	pop	ix
	ret
;lcdlib.c:275: static void _lcd_write_no_busy_check(unsigned char rs, unsigned char data)
;	---------------------------------
; Function _lcd_write_no_busy_check
; ---------------------------------
__lcd_write_no_busy_check:
;lcdlib.c:277: unsigned char LCD = 0;
	ld	c, #0x00
;lcdlib.c:280: _OUT_LCD( LCD );
	ld	hl,#_DEBUG_PIOA_DATA + 0
	ld	(hl), #0x00
	push	bc
	call	_DEBUG_PIOOUT
	pop	bc
;lcdlib.c:281: if( rs == 1 )
	ld	hl, #2+0
	add	hl, sp
	ld	a, (hl)
	dec	a
	jr	NZ,00102$
;lcdlib.c:283: LCD |= 1<<LCD_RS;
	ld	c, #0x40
00102$:
;lcdlib.c:285: _OUT_LCD( LCD );
	ld	hl,#_DEBUG_PIOA_DATA + 0
	ld	(hl), c
	push	bc
	call	_DEBUG_PIOOUT
	call	__lcd_wait_300ns
	pop	bc
;lcdlib.c:290: LCD |= ( data & 0x0F );
	ld	hl, #3+0
	add	hl, sp
	ld	a, (hl)
	and	a, #0x0f
	or	a, c
	ld	c, a
;lcdlib.c:291: _OUT_LCD( LCD );
	ld	hl,#_DEBUG_PIOA_DATA + 0
	ld	(hl), c
	push	bc
	call	_DEBUG_PIOOUT
	call	__lcd_wait_300ns
	call	__lcd_wait_300ns
	pop	bc
;lcdlib.c:296: LCD |= 1<<LCD_EN;
	set	4, c
;lcdlib.c:297: _OUT_LCD( LCD );
	ld	hl,#_DEBUG_PIOA_DATA + 0
	ld	(hl), c
	push	bc
	call	_DEBUG_PIOOUT
	call	__lcd_wait_300ns
	pop	bc
;lcdlib.c:301: LCD &= ~( 1<<LCD_EN );
	ld	a, c
	and	a, #0xef
	ld	(_DEBUG_PIOA_DATA+0), a
;lcdlib.c:302: _OUT_LCD( LCD );
	call	_DEBUG_PIOOUT
;lcdlib.c:303: _lcd_wait_300ns();
;lcdlib.c:304: }
	jp	__lcd_wait_300ns
;lcdlib.c:321: static void _lcd_init_hw_specific(void)
;	---------------------------------
; Function _lcd_init_hw_specific
; ---------------------------------
__lcd_init_hw_specific:
;lcdlib.c:323: DEBUG_PIOOUT_SETUP();
;lcdlib.c:324: }
	jp	_DEBUG_PIOOUT_SETUP
	.area _CODE
	.area _INITIALIZER
	.area _CABS (ABS)
