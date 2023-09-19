
; Example of building a WinCE executable using direct coding

	format	PE GUI
	entry	Start

section '.text' data code readable writeable executable

Start:
	mov	r0,0			;window owner (NULL)
	adr	r1,Text			;the text
	adr	r2,Caption		;the caption
	mov	r3,0			;style (MB_OK)
	ldr	pc,[MessageBoxW]	;display message and exit

Text	du	'Hello WinCE world',0
Caption	du	'ARM small PE',0

	align	4

data import

	dw	RVA core_imports,0,0,RVA core_name,RVA core_imports
	rw	5

	core_imports:
	MessageBoxW	dw	0x8000035A
			dw	0

	core_name	db	'COREDLL.DLL',0

	align	4

end data
