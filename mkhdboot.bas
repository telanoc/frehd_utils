10 REM MKHDBOOT/BAS by Pete Cervasio 07 MAR 2023
20 REM This program is designed to create an initial .HDV file header
30 REM that will wind up being a bootable disk on a FreHD hard disk
40 REM emulator once it's formatted.  Tested on LSDOS631 and LDOS531
50 REM 22 MAR 2023: Need to set OS type.  Added gosub to get it and
60 REM set the header value.  Also, don't show 'rshard' reminders if
70 REM the OS chosen isn't LDOS/LS-DOS.
80 REM --------------------------------------------------------------
90 CLEAR 500: DEFINT A-Z
100 DN$="harddisk/hdv" : REM Name of the file we are creating
110 HEADS=8            : REM Total of 8 heads on this drive
120 TTLCYL=406         : REM Total number of cylinders on the drive
130 D0CYL=203         : REM Number of cylinder for drive :0
140 GRANS=8           : REM 8 grans per cylinder
150 DIR=101           : REM Dir of :0 stored on cylinder 101
160 GOSUB 590         : REM Get the OS type from the user
170 OPEN"R",1,DN$
180 FIELD 1,32 AS A$, 16 AS B$, 208 AS C$
190 LSET A$=STRING$(32,0)
200 LSET B$="rshard"+RS$
210 LSET C$=STRING$(208,0)
220 Q$=""
230 FOR I = 0 TO 15
240   READ DAT
250   IF I = 11 THEN DAT = OS : REM set os type value
260   Q$ = Q$+ CHR$(DAT)
270 NEXT
280 FOR I=17 TO 26 : Q$ = Q$+CHR$(0):NEXT
290 TTL$=MKI$(TTLCYL)
300 Q$ = Q$ + CHR$(HEADS)
310 Q$ = Q$ + MID$(TTL$,2,1)
320 Q$ = Q$ + MID$(TTL$,1,1)
330 Q$ = Q$ + CHR$(0)
340 Q$ = Q$ + CHR$(GRANS)
350 Q$ = Q$ + CHR$(DIR)
360 LSET A$=Q$
370 PUT 1,1
380 CLOSE 1
390 Q$=CHR$(34)
400 PRINT "Done."
410 PRINT "Now put this in your FreHD directory using"
420 PRINT "  export2 " ;DN$; " menuname"
430 PRINT "  vhdutl (mnt,addr=1,vhd=";Q$;"menuname";Q$;")"
440 IF RS$<>" " THEN PRINT "system (drive=x,disable,driver=";Q$;"rshard";RS$;Q$;")"
450 PRINT:PRINT "Remember these values:"
460 PRINT "  Total Cylinders: ";TTLCYL
470 PRINT "  Total # heads  : ";HEADS
480 PRINT "  Drive :0 heads : 1"
490 PRINT "  Drive :0 cyls  :";D0CYL
500 IF RS$=" " THEN END
510 PRINT:PRINT "Then using rsform";RS$;" make partitions as normal."
520 PRINT "Any drive other than :0 can have more 203 cylinders"
530 PRINT "but I have had no luck booting with > 203 on drive :0"
540 END
550 REM first 16 data bytes of the header.  The 1 in the 9th
560 REM position is the boot/menu enable flag. 0 would turn it off.
570 REM 12th position is OS type, which is now set by the gosub
580 DATA 86, 203, 16, 25, 1, 4, 0, 0, 1, 0, 66, 0, 3, 12, 123, 0
590 PRINT:PRINT "Please enter the number corresponding do the type DOS"
600 PRINT "you are installing on this hard disk image.  The FreHD"
610 PRINT "ROM needs to know this to boot it."
620 PRINT
630 PRINT "  0 - Model 4 LSDOS 6.3.1"
640 PRINT "  1 - Model 3 LDOS 5.3.1"
650 PRINT "  2 - Model 4 CP/M"
660 PRINT "  3 - Model 3 Newdos 2.5"
670 PRINT "  4 - Model 1 LDOS 5.3.1"
680 PRINT "  5 - Model 1 Newdos 2.5"
690 PRINT "  6 - Max-80 MAX_OS"
700 PRINT: PRINT "Enter value: ";:LINE INPUT AN$
710 IF AN$="" OR VAL(AN$)<0 OR VAL(AN$)>6 THEN GOTO 590
720 OS=VAL(AN$): RS$=MID$("65  1 M",OS+1,1): RETURN
