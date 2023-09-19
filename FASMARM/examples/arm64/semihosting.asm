SemiHosting			= 0xf000
SYS_WRITEC			= 3
SYS_WRITE0			= 4
ADP_Stopped_ApplicationExit	= 0x20026
angel_SWIreason_ReportException	= 0x18

	processor cpu64_v8
	code64

	adr	x0,stack_base
	mov	sp,x0
	adr	x1,hello_world
	bl	show_string

	adr	x1,running_at
	bl	show_string
	adr	x0,$$
	bl	show_hex

	adr	x1,exec_level
	bl	show_string
	mrs	x0,CurrentEL
	ubfx	x0,x0,2,2
	bl	show_hex

	movz	x1,ADP_Stopped_ApplicationExit and 0xffff
	movk	x1,ADP_Stopped_ApplicationExit and 0xffff shl 16
	stp	x1,xzr,[sp,-16]!
	mov	x1,sp
	mov	x0,angel_SWIreason_ReportException
	hlt	SemiHosting

show_hex:
	;x0 = the value
	clz	x2,x0
	bic	x2,x2,3
	lslv	x3,x0,x2
	sub	sp,sp,16
    .loop:
	ror	x3,x3,64-4
	and	x1,x3,0xf
	cmp	x1,9
	add	x0,x1,'A'-10
	add	x1,x1,'0'
	csel	x1,x1,x0,ls
	strb	w1,[sp]
	mov	x1,sp
	mov	x0,SYS_WRITEC
	hlt	SemiHosting
	add	x2,x2,4
	tbz	x2,6,.loop
	add	sp,sp,16
show_crlf:
	adr	x1,crlf
show_string:
	;x1 = the string
	mov	x0,SYS_WRITE0
	hlt	SemiHosting
	ret

hello_world:	db 'Hello World!',13,10
crlf:		db 13,10,0
running_at:	db '  Start address: 0x',0
exec_level:	db 'Execution level: ',0

	align	16
	rb	0x20
stack_base:
