10 REM MKHDBOOT/BAS by Pete Cervasio 07 MAR 2023
20 REM This program is designed to create an initial .HDV file header
30 REM that will wind up being a bootable disk on a FreHD hard disk
40 REM emulator once it's formatted.  Tested on LSDOS631 and LDOS531
50 REM --------------------------------------------------------------
60 CLEAR 500: DEFINT A-Z
70 DN$="harddisk/hdv" : REM Name of the file we are creating
80 HEADS=8            : REM Total of 8 heads on this drive
90 TTLCYL=406         : REM Total number of cylinders on the drive
100 D0CYL=203          : REM Number of cylinder for drive :0
110 GRANS=8            : REM 8 grans per cylinder
120 DIR=101           : REM Dir of :0 stored on cylinder 101
130 OPEN"R",1,DN$
140 FIELD 1,32 AS A$, 16 AS B$, 208 AS C$
150 LSET A$=STRING$(32,0)
160 LSET B$="rshard6"
170 LSET C$=STRING$(208,0)
180 Q$=""
190 FOR I = 1 TO 16
200   READ DAT
210   Q$ = Q$+ CHR$(DAT)
220 NEXT
230 FOR I=17 TO 26 : Q$ = Q$+CHR$(0):NEXT
240 TTL$=MKI$(TTLCYL)
250 Q$ = Q$ + CHR$(HEADS)
260 Q$ = Q$ + MID$(TTL$,2,1)
270 Q$ = Q$ + MID$(TTL$,1,1)
280 Q$ = Q$ + CHR$(0)
290 Q$ = Q$ + CHR$(GRANS)
300 Q$ = Q$ + CHR$(DIR)
310 LSET A$=Q$
320 PUT 1,1
330 CLOSE 1
340 Q$=CHR$(34)
350 PRINT "Done."
360 PRINT "Now put this in your FreHD directory using"
370 PRINT "  export2 " ; DN$; " menuname"
380 PRINT "  vhdutl (mnt,addr=1,vhd=";Q$;"menuname";Q$;")"
390 PRINT "system (drive=x,disable,driver=";Q$;"rshard6";Q$;")"
400 PRINT:PRINT "Remember these values:"
410 PRINT "  Total Cylinders: "; TTLCYL
420 PRINT "  Total # heads  : "; HEADS
430 PRINT "  Drive :0 heads : 1"
440 PRINT "  Drive :0 cyls  :";D0CYL
450 PRINT:PRINT "Then use rsform6 make partitions as normal."
460 PRINT "Any drive other than :0 can have more 203 cylinders"
470 PRINT "but I have had no luck booting with > 203 on drive :0"
480 REM first 16 data bytes of the header.  The 1 in the 9th
490 REM position is the boot/menu enable flag. 0 would turn it off.
500 DATA 86, 203, 16, 25, 1, 4, 0, 0, 1, 0, 66, 0, 3, 12, 123, 0
