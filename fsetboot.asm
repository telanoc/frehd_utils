;
; fsetboot.z80
;
; Copyright 2023, Pete Cervasio <cervasio@airmail.net>
; Copyright Timothy Mann, 1997 and Frederic Vecoven, 2013
;
; This software may be copied, modified, and used for any
; purpose without fee, provided that (1) the above copyright
; notice is retained, and (2) modified versions are clearly
; marked as having been modified, with the modifier's name and
; the date included.  
;
; A program for FreHD based systems to turn on or off the flag
; in a hard disk image file which marks it as bootable (and to
; show up in the FreHD menu).  In my testing, a hard disk would
; only boot if its drive :0 was set up with 203 cylinders or
; fewer.  It also had to use only one head.  Drives :1 and up 
; could be set as 406 cylinders and more heads, but I was not
; able to boot from a disk set up that way.
;
; Many chunks were pulled from the 'import2' utility source
; because that program was already set up to run on the
; various Model 1, III and 4 systems.  This does no DOS calls
; other than to display information and exit so it should 
; "just work" on them.
;
; Usage: 
; =====
;
; 1) Get the name of the hard disk image from Frehd with
;
;    vhdutl (dir)
;
; 2) Set byte 8 of the hard disk header to 1 by
;
;    fsetboot frehd_filename
;
;    To turn the boot flag off, use:
;
;    fsetboot -n frehd_filename
;
;---------------------------------------------------------------
;

;; Interface defines
DATA2		equ	0c2h
SIZE2		equ	0c3h
COMMAND2	equ	0c4h
ERROR2		equ	0c5h
STATUS		equ	0cfh

;; FreHD commands we use
OPENFILE	equ	03h
READFILE	equ	04h
WRITEFILE	equ	05h
CLOSEFILE	equ	06h
SEEKFILE	equ	0bh

;; FatFS flags
FA_OPEN_EXISTING equ	00h
FA_READ		 equ	01h
FA_WRITE	 equ	02h
FA_CREATE_NEW	 equ	04h
FA_CREATE_ALWAYS equ	08h
FA_OPEN_ALWAYS	 equ	10h

;; Misc
LF		equ	10
CR		equ	13
ETX		equ	3

REED_SIG1	equ	56h
REED_SIG2	equ	0cbh

;; Model I/III addresses
@error		equ	4409h
@exit		equ	402dh
@abort		equ	4030h	    
@put		equ	001bh
dodcb$		equ	401dh

;; Model 4 SVCs
@svc		equ	40  ; rst address for SVCs
@error6		equ	26
@exit6		equ	22
@abort6		equ	21
@dsply6		equ	10

	org	5200h

;;
;; Jump tables for OS independence
;;
startj:
error:	call @error
	ret
exit:	call @exit
	ret
abort:	call @abort
	ret
dsply:	call dsply5
	ret
endj:

;; Model 4 jump table
startj6:
	ld a, @error6
	rst @svc
	ret
	ld a, @exit6
	rst @svc
	ret
	ld a, @abort6
	rst @svc
	ret
	ld a, @dsply6
	rst @svc
	ret
;
;	Program start location
;
start:	
	ld a, (000ah)		; Model 4?
	cp 40h
	jr z, not4
	push hl
	ld de, startj
	ld hl, startj6
	ld bc, endj - startj
	ldir
	pop hl
not4:
flag0:	ld a, (hl)		; look for flags
	cp ' '
	jp c, usage		; error if line ends here
	jr nz, flag1
	inc hl
	jr flag0
flag1:	cp '-'
	jr nz, setbt
	inc hl
	ld a, (hl)
	or 20h			; Force to lowercase
	cp 'n'			; The only option we allow
	jr nz, usage
	inc hl
	ld a, 0
	ld (bootval), a
	jr flag0

usage:	ld hl, usemsg
	call  dsply
	ld hl, 1
	jp exit
;
;
;
setbt:	ld (hdname), hl		; Save pointer to name
	ld de, secbuf+1
	ld a, ' '
setb1	cp (hl)			; Put filename into secbuf
	ldi
	jr c,setb1
	dec de			; nul terminate it
	sub a
	ld (de), a
;
; Greet user and say what we're going try to do
;
	ld hl, welcmsg
	call dsply
	ld a, (bootval)
	or a
	jr z, clearit
	ld hl, setm
	jr cont
clearit ld hl, clrm
cont	call dsply
	ld hl, bfmsg
	call dsply
	ld hl, (hdname)
	call dsply
;
; set up to open the file
;
	ld hl,secbuf+1
	ld b, 2			; length = 2 (flag + null-terminator)
	ld a, 0			; null-terminator
stlen1:	cp (hl)
	jr z, stlen2
	inc b			; found a character
	inc hl
	jr stlen1
;
; open the disk image
;
stlen2:	ld a, OPENFILE
	out (COMMAND2), a	; send OPENFILE command
	call wait
	ld a, b
	out (SIZE2), a		; send SIZE2
	ld c, DATA2
	ld hl, secbuf
	ld (hl), FA_OPEN_EXISTING|FA_READ|FA_WRITE
	otir
	call wait		; Won't return if there's an error
;
; Read the header into secbuf
;
	ld hl,secbuf
	ld a,32
	out (SIZE2),a		; request 32 bytes

	ld a, READFILE
	out (COMMAND2), a	; read
	call wait
	
	ld bc, 0000h
	in a, (STATUS)		; get status. DRQ set means we read something
	and 08h
	jr z, readok
	in a, (SIZE2)
	ld c, a
	or a
	jr nz, readok
	ld b, 1
readok:	
	ld b,c
	ld c, DATA2
	ld hl, secbuf
	inir			; read buffer from interface
;
; Make sure this is really a Reed hard disk image
;
	ld a, (secbuf)		; Check for the Reed header signature
	cp REED_SIG1
	jp nz,notreed
	ld a, (secbuf+1)
	cp REED_SIG2
	jp nz,notreed

;
; Is the boot flag what we expected?
;
	ld hl,secbuf+8		; point to byte 8 in the header
	ld a,(bootval)		; Get our desired boot value
	cp (hl)			; Is it alreedy set that way?
	jr z,already
	ld (hl),a		; Set the value in the header
;
; Seek to offset 0 in the header
;
	ld a,SEEKFILE
	out (COMMAND2),a
	call wait
	xor a
	ld b,4
seeklp	out (DATA2),a		; DWORD zero
	djnz seeklp
	call wait
;
; and write it back out
;
	ld bc,0
	ld a, WRITEFILE		; send write command
	out (COMMAND2), a
	call wait
	ld a,32			; send size to interface
	out (SIZE2), a
	ld b, a
	ld c, DATA2
	ld hl, secbuf
	otir			; send data
	call wait		; wait until it's written

	ld hl,itsdone
	call dsply
;
; Now close the file
;
closit:
	ld a, CLOSEFILE		; send close file
	out (COMMAND2), a
	call wait
	jr getout

already ld hl,itsthat
	call dsply

getout: ld  hl,0
	jp exit

;
; Display message in HL.  03h terminate, 0dh newline and terminate.
;
dsply5:	ld de, dodcb$
	push hl
dsply0:	ld a, (hl)
	cp 03h
	jr z, dsply1
	push af
	call @put
	pop af
	inc hl
	cp 0dh
	jr nz, dsply0
dsply1:	pop hl
	ret
;
; wait until the interface is ready
;
wait:	ex (sp),hl
	ex (sp),hl			; small delay to settle the controller
wait1:	in a, (STATUS)
	rlca
	jr c, wait1
	in a, (STATUS)			; read status again
	and 01h				; nz = error
	jr nz, uerror
	ret
;
; interface error
;
uerror: ld hl, error_m		; display error prefix
	call dsply
	in a, (ERROR2)		; get error number
	cp 15h			; check error number.
	jr c, uerrok
	ld hl,ue1		; Convert error code to hex for
	ld b,a			; display, in case it's helpful.
	rra
	rra
	rra
	rra
	and 0fh
	cp  0ah
	sbc a,69h
	daa
	ld (hl),a
	inc hl
	ld a,b
	and 0fh
	cp 0ah
	sbc a,69h
	daa
	ld (hl),a
	sub a			; A=0 unknown error 
uerrok:	ld l, a
	ld h, 00h
	add hl, hl		; pointers are 2 bytes
	ld de, error_table
	add hl, de		; hl points to the pointer
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a			; hl points to the string
	call dsply
	jp abort
;
; Not a reed hard disk image
;
notreed:
	ld hl, notreedmsg
	call dsply
	jp closit
;
; Data
;
bootval	db	1		; Value to set in the header
hdname	dw 0
;
; Messages
;
welcmsg db	"fsetboot - Set or clear bootable flag of FreHD disk images",CR
	db	"Copyright 2023, Pete Cervasio <cervasio@airmail.net>",LF,CR
usemsg	db	"Usage: fsetboot [-n] diskimg.name",CR
clrm	db	"Clearing",ETX
setm	db	"Setting",ETX
bfmsg	db	" boot flag of ",ETX
issetm	db	"Boot flag already set",CR
isclrm	db	"Boot flag already clear",CR
itsthat db	"NOTE: The header is already set that way.  Nothing done.",CR
itsdone db	"The header has been changed.",CR
notreedmsg db	"That file does not appear to be a hard disk image!",CR

;
; FreHD error messages
;
error_m:		defb 'Error: ', 03h
fr_unknown:		defb 'Unknown error '			; 0
ue1			defb '00H',CR
fr_disk_err:		defb 'Disk error', 0dh			; 1
fr_int_err:		defb 'Internal error', 0dh		; 2
fr_not_ready:		defb 'Drive not ready', 0dh		; 3
fr_no_file:		defb 'File not found', 0dh		; 4
fr_no_path:		defb 'Path not found', 0dh		; 5
fr_invalid_name:	defb 'Invalid pathname', 0dh		; 6
fr_denied:		defb 'Access denied', 0dh		; 7
fr_exist:		defb 'File exists', 0dh			; 8
fr_invalid_obj:		defb 'File/dir object invalid', 0dh	; 9
fr_write_protected:	defb 'Write protected', 0dh		; 10
fr_invalid_drive:	defb 'Invalid drive', 0dh		; 11
fr_not_enabled:		defb 'Volume not mounted', 0dh		; 12
fr_no_fs:		defb 'No FAT fs found', 0dh		; 13
fr_mkfs_aborted:	defb 'mkfs aborted', 0dh		; 14
fr_timeout:		defb 'Timeout detected', 0dh		; 15
fr_locked:		defb 'File locked', 0dh			; 16
fr_not_enough_core:	defb 'Not enough core', 0dh		; 17
fr_too_many_open_files:	defb 'Too many open files', 0dh		; 18
fr_invalid_param:	defb 'Invalid parameter', 0dh		; 19
fr_disk_full:		defb 'Disk full', 0dh			; 20

error_table:
	dw	fr_unknown, fr_disk_err, fr_int_err, fr_not_ready
	dw	fr_no_file, fr_no_path,	fr_invalid_name, fr_denied 
	dw	fr_exist, fr_invalid_obj, fr_write_protected, fr_invalid_drive
	dw	fr_not_enabled, fr_no_fs, fr_mkfs_aborted, fr_timeout
	dw	fr_locked, fr_not_enough_core, fr_too_many_open_files
	dw	fr_invalid_param, fr_disk_full



secbuf	ds	256,0

	end start
