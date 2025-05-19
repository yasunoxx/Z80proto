;	fgetc_cons
	INCLUDE "../../z80sioctc.def"
;	INCLUDE	"../../memmap.def"
	PUBLIC	fgetc_cons
	extern	getchar_SIO0

.fgetc_cons
	call	getchar_SIO0
;
loop:
	cp	0	;; FIXME: NULL termination, or F_STAT_RECEIVE
	jr	z, loop
	ld	l, a
;
	ret
