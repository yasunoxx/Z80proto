all: embedded_clib2.lib

embedded_clib2.lib: fputc_cons.asm fgetc_cons.asm
	z88dk-z80asm -d -DFORembedded -xembedded_clib2 @clib2.lst

clean:
	$(RM) *.bin *.i *.lib *.op* *~ *.lis *.map *.sym
