
; Example of building a simple WinCE application using high level macros

	include	'wincex.inc'

.code

proc Start base sp uses[r0-r12,r14]
  locals
	outbuff	rb 0x400
      virtual
	regs	rw 14
	stack	dw ?
      end virtual
  endl
	mov	v7,outbuff
	mov	v1,0
    .again:
	mov	a1,'R'
	strh	a1,[v7],2
	apscall	itou32,v7,v1
	sub	v7,a1,2
	apscall	string_copy_atou32,v7,'=0x'
	sub	v7,a1,2
	cmp	v1,13
	lealt	v2,[regs]
	ldrlt	v3,[v2,v1,lsl 2]	;Get registers R0-R12
	leaeq	v3,[stack]		;Calculate original R13 (SP)
	cmp	v1,14
	ldreq	v3,[regs+13*4]		;Get register R14
	leahi	v3,[Start]		;Calculate original R15 (PC)
	apscall	htou32,v7,v3,8
	sub	v7,a1,2
	apscall	string_copy_atou32,v7,' ('
	sub	v7,a1,2
	apscall	itou32,v7,v3
	sub	v7,a1,2
	apscall	string_copy_atou32,v7,<')',13,10>
	sub	v7,a1,2
	add	v1,v1,1
	cmp	v1,15
	bls	.again
	apscall	MessageBoxW,0,addr outbuff,*'WinCE Start registers',0
	ret
endp

proc string_copy_atou32 nospill,dest,source
    .again:
	ldrb	a3,[source],1
	strh	a3,[dest],2
	cmp	a3,0
	bne	.again
	ret
endp

proc itou32 nospill,dest,value
	mov	ip,0xffffffcd
	and	ip,ip,0xffffccff
	mov	a4,0
	add	ip,ip,ip,lsl 16		;ip=0xcccccccd == int(2^35/10+.5)
    .next:
	strb	a4,[sp,-1]!
	mov	a3,value
	umull	a4,value,ip,value
	movs	value,value,lsr 3	;value=quotient
	sub	a4,a3,value,lsl 3
	sub	a4,a4,value,lsl 1	;a4=remainder
	add	a4,a4,'0'
	bne	.next
    .digit:
	strh	a4,[dest],2
	ldrb	a4,[sp],1
	cmp	a4,0
	bne	.digit
	strh	a4,[dest],2
	ret
endp

proc htou32 nospill,dest,value,nibbles
    ;if "nibbles" is zero then leading zeros are suppressed
	clz	a4,value
	rsb	a4,a4,35
	cmp	nibbles,8
	movhi	nibbles,8
	cmp	nibbles,0
	andeq	nibbles,a4,not 3
	movne	nibbles,nibbles,lsl 2
    .again:
	sub	nibbles,nibbles,4
	mov	a4,value,ror nibbles
	and	a4,a4,0xf
	add	a4,a4,'0'
	cmp	a4,'9'
	addhi	a4,a4,'A'-'9'-1
	strh	a4,[dest],2
	cmp	nibbles,0
	bgt	.again
	mov	a4,0
	strh	a4,[dest],2
	ret
endp

.end Start

section '.rsrc' resource data readable

	RT_VERSION	=16
	LANG_NEUTRAL	=0
	LANG_ENGLISH	=9
	SUBLANG_DEFAULT	=400h
	VOS__WINDOWS32	=4
	VFT_APP		=1
	VFT2_UNKNOWN	=0

	directory	RT_VERSION,versions
	resource	versions,1,LANG_NEUTRAL,version
	versioninfo	version,VOS__WINDOWS32,VFT_APP,VFT2_UNKNOWN,LANG_ENGLISH+SUBLANG_DEFAULT,0,\
			'FileDescription','Demonstration of FASMARM for WinCE assembly',\
			'LegalCopyright','Copyright (C) 2006, revolution',\
			'FileVersion','0.0.0.0',\
			'ProductVersion','0.0.0.0',\
			'OriginalFilename','ARMPE4.EXE'
