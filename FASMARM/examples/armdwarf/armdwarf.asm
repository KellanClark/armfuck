	format ELF dwarf executable at 0
	entry start
	section 'one' executable readable writeable align 020h

start:	mov	r1,string_hello
	mov	r0,4		;SYS_WRITE0
	swi	0x123456	;Multi-ICE DCC semihosting
	mov	r0,18h		;angel_SWIreason_ReportException
	mov	r1,20000h	;Software reason code
	orr	r1,r1,26h	;ADP_Stopped_ApplicationExit
	swi	0x123456	;Multi-ICE DCC semihosting

string_hello	db	'Hello ARM semi-hosting world',13,10,0
