10 DEFINT A-Z
20 REM --------------------------------------------------------------
30 REM Program to read DOS data and create a customized HDBOOT/FIX
40 REM specific to the currently loaded drivers.
50 REM --
60 REM Basically, this fills in the vv, ww, xx, yy, and zz values
70 REM in A. Rubin's HDBT2 patches.
80 REM Tested in LSDOS 6.3.1L only.
90 REM --------------------------------------------------------------
100 GOSUB 710
110 PRINT "Values determined for HDBT2/TXT:"
115 print "DBLBIT ="; dblbit
120 PRINT "vv = "; VV$
130 PRINT "ww = "; RIGHT$("0" + HEX$(WW), 2)
140 PRINT "xx = "; RIGHT$("0" + HEX$(XX), 2)
150 PRINT "yy = "; RIGHT$("0" + HEX$(YY), 2)
160 PRINT "zz ="; ZZ$
169 rem end : rem In case I just want to see the values
170 OPEN "o",1,"hdboot/fix:0"
180 PRINT #1, ".HDBOOT/FIX v2.03 -- Patch to BOOT/SYS for 4P HD boot -- A. Rubin"
190 PRINT #1, ".Usage: PATCH BOOT/SYS.LSIDOS:0 USING HDBOOT"
200 PRINT #1, "."
210 PRINT #1, "D00,4D="; RIGHT$("0"+HEX$(XX),2);" 00 00 00 00 00 00 00"
220 PRINT #1, "F00,4D=12 FD CB 04 6E 28 01 87"
230 PRINT #1, "."
240 PRINT #1, "D00,5A="; RIGHT$("0"+HEX$(YY),2)
250 PRINT #1, "F00,5A=06"
260 PRINT #1, "D00,9F=C0 43"
270 PRINT #1, "F00,9F=70 04"
280 PRINT #1, "D01,41=18 0D E5 21 A0 43 11 71 04 01 08 00 ED B0 C9"
290 PRINT #1, "F01,41=1E 00 CD 74 43 3A CD 12 E6 20 21 74 04 B6 77"
300 PRINT #1, "D01,6F=21 38 02 18 CF"
310 PRINT #1, "F01,6F=C3 38 02 00 00"
320 PRINT #1, "D01,7C=C0 43 E1 C1 00 00"
330 PRINT #1, "F01,7C=96 43 E1 C1 E6 1C"
340 PRINT #1, "."
350 PRINT #1, "D01,9E=41 52 A8 43";ZZ$; " 3E 09 90 20 10 F3 CD C0"
360 PRINT #1, "F01,9E=ED 51 CD D9 43 DB F0 CB 47 20 FA 7B D3 F2 3E 81 D3 F4"
370 PRINT #1, "D01,B0=43 FB 3E 05 C0 3A 79 04 92 3E 06 28 01 AF A7 C9"
380 PRINT #1, "F01,B0=D5 11 02 C1 3E 80 CD D9 43 3E C0 D3 E4 DB F0 A3"
390 PRINT #1, "."
400 PRINT #1, "D01,C0=E5 D5 3E 85 D3 84 D3 9C 4B 5A 16 00 79 "; VV$
410 PRINT #1, "F01,C0=28 FB ED A2 7A D3 F4 ED A2 20 FA 18 FE D1 D1 AF"
420 PRINT #1, "D01,D0=06 0C 3E 02 CF F5 3E 86 D3 9C D3 84 F1 D1 E1"
430 PRINT #1, "F01,D0=D3 E4 3E 81 D3 F4 DB F0 C9 D3 F0 06 18 10 FE"
440 PRINT #1, "."
450 PRINT #1, "D01,F5=02 03 EB 29 EB D6 "; RIGHT$("0"+HEX$(WW),2); " D8 4F 13 C9"
460 PRINT #1, "F01,F5=00 00 00 00 00 00 00 00 00 00 00"
470 PRINT #1, ".End of HDBOOT/FIX patch"
480 CLOSE
490 REM ---------------------------------------
500 REM HDSYS0: This is the same for all setups
510 REM ---------------------------------------
520 OPEN "O",1,"hdsys0/fix:0"
530 PRINT #1, ".HDSYS0/FIX v2.03 -- Patch to SYS0/SYS for 4P HD boot -- A. Rubin"
540 PRINT #1, ".Usage: PATCH SYS0/SYS.SYSTEM6:0 USING HDSYS0"
550 PRINT #1, "D0C,B9=00 00 00"
560 PRINT #1, "F0C,B9=31 80 03"
570 PRINT #1, "D0D,0A=00 00 00 00 00 00 00 00 00 00 00 3E D0 D3 F0 06 80 10 FE"
580 PRINT #1, "F0D,0A=3A 9D 43 E6 03 47 21 73 04 7E E6 FC B0 77 DB F1 32 75 04"
590 PRINT #1, "D0E,A6=00 00 00"
600 PRINT #1, "F0E,A6=C2 A0 19"
610 PRINT #1, "D0E,E8=00"
620 PRINT #1, "F0E,E8=C0"
630 PRINT #1, "D0F,1A=FE"
640 PRINT #1, "F0F,1A=0C"
650 PRINT #1, ".End of HDSYS0/FIX patch"
660 CLOSE
670 PRINT "To apply these:"
680 PRINT "PATCH BOOT/SYS.LSIDOS:0 USING HDBOOT"
690 PRINT "PATCH SYS0/SYS.SYSTEM6:0 USING HDSYS0"
700 END
710 REM --------------------------------------------------------------
720 REM Get Drive Params
730 DCT = &H470
740 IF PEEK(DCT+3) AND &H8 = 0 THEN PRINT "Drive :0 is not a hard disk!":END
750 ZZ$="":FOR X = 3 TO 8 : ZZ$ = ZZ$ + " " + RIGHT$("0"+HEX$(PEEK(DCT+X)),2): NEXT
760 DBLBIT = ((PEEK(DCT+4) AND &H20) = &H20)
770 IF DBLBIT THEN VV$ = "CD F7 43" ELSE VV$ = "00 00 00"
780 WW = &H20
790 IF DBLBIT THEN XX=WW*2 ELSE XX=WW
800 YY = XX / 8
810 RETURN
