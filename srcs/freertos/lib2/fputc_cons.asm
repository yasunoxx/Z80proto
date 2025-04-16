;	fputc_cons
;	INCLUDE "../../z80sioctc.def"
;	INCLUDE	"../../memmap.def"
	PUBLIC  fputc_cons_native
	PUBLIC  fputc_cons
	extern	putchar_SIO0

fputc_cons:
.fputc_cons_native
	jp	putchar_SIO0
