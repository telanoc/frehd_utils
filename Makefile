#=========================================================================
# $Header$
# Module: Makefile
# Date: 12 March 2023
# Author: Pete Cervasio
# Wants George Phillips zmac assembler from github.com/gp48k/zmac
#=========================================================================

ZMACFLAGS_LDOS = --mras -c

.SUFFIXES:      .asm .cmd .dct .man .txt .hex .bin .com

.asm.cmd:
	zmac $(ZMACFLAGS_LDOS) -o $*.cmd -o $*.lst $<

all: fsetboot.cmd

fsetboot.cmd: fsetboot.asm Makefile

clean:
	rm -f *.cmd *.lst

