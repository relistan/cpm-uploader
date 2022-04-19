;==================================================================================
; Contents of this file are copyright Grant Searle
; HEX routine from Joel Owens.
;
; You have permission to use this for NON COMMERCIAL USE ONLY
; If you wish to use it elsewhere, please include an acknowledgement to myself.
;
; http://searle.hostei.com/grant/index.html
;
; eMail: home.micros01@btinternet.com
;
; If the above don't work, please perform an Internet search to see if I have
; updated the web page hosting service.
;
;==================================================================================

; Modified by Karl Matthias -- April 2022
; - added commentary
; - now prints out to the console the filename it received

TPA	.EQU	100H
REBOOT	.EQU	0H
BDOS	.EQU	5H
CONIO	.EQU	6
CONINP	.EQU	1
CONOUT	.EQU	2
PSTRING	.EQU	9
MAKEF	.EQU	22
CLOSEF	.EQU	16
WRITES	.EQU	21
DELF	.EQU	19
SETUSR	.EQU	32

CR	.EQU	0DH
LF	.EQU	0AH

FCB	.EQU	05CH
BUFF	.EQU	080H

	.ORG TPA

; Zero out the variables
	LD	A,0
	LD	(buffPos),A
	LD	(checkSum),A
	LD	(byteCount),A
	LD	(printCount),A
	LD	HL,BUFF
	LD	(buffPtr),HL


WAITLT:	CALL	GETCHR
	CP	'U'
	JP	Z,SETUSER
	CP	':'
	JR	NZ,WAITLT

	; Remove any pre-existing file by this name
	LD	C,DELF
	LD	DE,FCB
	CALL	BDOS

	; Create the new file
	LD	C,MAKEF
	LD	DE,FCB
	CALL	BDOS

	; Print out starting message
	LD	DE,processMess
	LD	C,PSTRING
	CALL	BDOS

; Print out the filename we're using
	LD IX,FCB ; Start from FCB (will be pre-incremented)
	LD B,11   ; B starts with 11 bytes (file name length)

PRINTFNAME:
	INC  IX			; Starting from 1 and then incrementing from there
	
	; Print a '.' after the ninth byte
	LD   A, B
	CP	 3
	JR   NZ,NODOT
	LD	 A,'.'		
	PUSH BC
	CALL PUTCHR		; Print a dot
	POP  BC
NODOT:
	LD	 A,(IX)
	CP	 ' '
	JR	 Z,NOPRINT

	LD   E,A
	LD   C,CONOUT	; Prepare to call CONOUT in BDOS
	PUSH BC
	CALL BDOS		; Call CONOUT
	POP  BC			; Restore some registers
NOPRINT:
	DJNZ PRINTFNAME

	LD   A,"\r"
	CALL PUTCHR
	LD   A,"\n"
	CALL PUTCHR


; Read a hex value from input and possibly write to disk once decoded and the
; buffer is full (128 bytes)
GETHEX:
	CALL 	GETCHR ; Load the first byte
	CP	'>'        ; Is it the ending sequence?
	JR	Z,CLOSE    ; If so, close out
	LD   B,A       ; Otherwise put in B
	PUSH BC        ; Store BC on the stack
	CALL GETCHR    ; Get the next char
	POP BC         ; Load up BC from the stack
	LD   C,A       ; Store A into C

	CALL BCTOA     ; Convert two ASCII hex bytes to 1 byte

	LD	B,A           ; Store our read byte into B
	LD	A,(checkSum)  ; Load up the checksum
	ADD	A,B           ; Add them
	LD	(checkSum),A  ; Store the result into the checksum
	LD	A,(byteCount) ; Load up the byteCount
	INC	A             ; Increment it
	LD	(byteCount),A ; Store into byteCount

	LD	A,B           ; Load B into A

	LD	HL,(buffPtr)  ; Load buffPtr into HL

	LD	(HL),A        ; Store our read byte into buffPtr
	INC	HL            ; Move the HL one to the right
	LD	(buffPtr),HL  ; Update buffPtr to address from HL

	LD	A,(buffPos)   ; Load A with buffPos
	INC	A             ; Increment A
	LD	(buffPos),A   ; Store A back to buffPos
	CP	80H           ; Is buffPos/A 128?

	JR	NZ,NOWRITE    ; If not, jump to NOWRITE

	LD	C,WRITES      ; Load WRITES into C
	LD	DE,FCB        ; Load up DE with FCB
	CALL	BDOS        ; Call BDOS to write to file
	LD	A,'.'         ; Load '.' into A
	CALL	PUTCHR      ; Output it to the terminal

    ; New line every 8K (64 dots)
	LD	A,(printCount)
	INC	A
	CP	64
	JR	NZ,noCRLF
	LD	(printCount),A
	LD	A,CR
	CALL	PUTCHR
	LD	A,LF
	CALL	PUTCHR
	LD	A,0
noCRLF:	LD	(printCount),A

	LD	HL,BUFF
	LD	(buffPtr),HL

	LD	A,0
	LD	(buffPos),A
NOWRITE:
	JR	GETHEX
	

CLOSE:

	LD	A,(buffPos)
	CP	0
	JR	Z,NOWRITE2

	LD	C,WRITES
	LD	DE,FCB
	CALL	BDOS
	LD	A,'.'
	CALL	PUTCHR

NOWRITE2:
	LD	C,CLOSEF
	LD	DE,FCB
	CALL	BDOS

; Byte count (lower 8 bits)
	CALL 	GETCHR
	LD   B,A
	PUSH BC
	CALL GETCHR
	POP BC
	LD   C,A

	CALL BCTOA
	LD	B,A
	LD	A,(byteCount)
	SUB	B
	CP	0
	JR	Z,byteCountOK

	LD	A,CR
	CALL	PUTCHR
	LD	A,LF
	CALL	PUTCHR

	LD	DE,countErrMess
	LD	C,PSTRING
	CALL	BDOS

	; Sink remaining 2 bytes
	CALL GETCHR
	CALL GETCHR

	JR	FINISH

byteCountOK:

; Checksum
	CALL 	GETCHR   ; Get a character
	LD   B,A         ; Store A into B
	PUSH BC          ; Push BC onto the stack
	CALL GETCHR      ; Get second character
	POP BC           ; Get BC off the stack
	LD   C,A         ; Copy A to C

	CALL BCTOA       ; Decode hex into A
	LD	B,A          ; Store the byte into B
	LD	A,(checkSum) ; Put current checksum into A
	SUB	B            ; Subtract byte we read
	CP	0            ; Was it 0?
	JR	Z,checksumOK ; If so, it's good

	LD	A,CR
	CALL	PUTCHR
	LD	A,LF
	CALL	PUTCHR

	LD	DE,chkErrMess
	LD	C,PSTRING
	CALL	BDOS
	JR	FINISH

checksumOK:
	LD	A,CR
	CALL	PUTCHR
	LD	A,LF
	CALL	PUTCHR

	LD	DE,OKMess
	LD	C,PSTRING
	CALL	BDOS
		


FINISH:
	LD	C,SETUSR
	LD	E,0
	CALL	BDOS

	JP	REBOOT


SETUSER:
	CALL	GETCHR
	CALL	HEX2VAL
	LD	E,A
	LD	C,SETUSR
	CALL	BDOS
	JP	WAITLT

	
; Get a char into A
;GETCHR: LD C,CONINP
;	CALL BDOS
;	RET

; Wait for a char into A (no echo)
GETCHR: 
	LD	E,$FF
	LD 	C,CONIO
	CALL 	BDOS
	CP	0
	JR	Z,GETCHR
	RET

; Write A to output
PUTCHR: LD C,CONOUT
	LD E,A
	CALL BDOS
	RET


;------------------------------------------------------------------------------
; Convert ASCII characters in B C registers to a byte value in A
;------------------------------------------------------------------------------
BCTOA	LD   A,B	; Move the hi order byte to A
	SUB  $30	    ; Take it down from Ascii
	CP   $0A	    ; Are we in the 0-9 range here?
	JR   C,BCTOA1	; If so, get the next nybble
	SUB  $07	    ; But if A-F, take it down some more
BCTOA1	RLCA		; Rotate the nybble from low to high
	RLCA		    ; One bit at a time
	RLCA		    ; Until we
	RLCA		    ; Get there with it
	LD   B,A	    ; Save the converted high nybble
	LD   A,C	    ; Now get the low order byte
	SUB  $30	    ; Convert it down from Ascii
	CP   $0A	    ; 0-9 at this point?
	JR   C,BCTOA2	; Good enough then, but
	SUB  $07	    ; Take off 7 more if it's A-F
BCTOA2	ADD  A,B	; Add in the high order nybble
	RET

; Change Hex in A to actual value in A
HEX2VAL SUB	$30
	CP	$0A
	RET	C
	SUB	$07
	RET


buffPos	.DB	0H
buffPtr	.DW	0000H
printCount .DB	0H
checkSum .DB	0H
byteCount .DB	0H
OKMess	.BYTE	"OK$"
chkErrMess .BYTE	"======Checksum Error======$"
countErrMess .BYTE	"======File Length Error======$"
processMess .BYTE "Processing file: $"
	.END
