format pe64 gui nx at 0x140000000
processor cpu64_v8

section '.text' code executable

entry $
	mov	x0,xzr
	adr	x1,hello
	adr	x2,title
	mov	x3,xzr
	ldr	x8,[MessageBox]
	blr	x8
	mov	x0,xzr
	ldr	x8,[ExitProcess]
	blr	x8

section '.data' data readable

	hello	db	'Hello, Win64 ARM world!',0
	title	db	'Win64 ARM',0

section '.idata' import data readable

	dw	0,0,0,rva user_name,rva user_table
	dw	0,0,0,rva kernel_name,rva kernel_table
	dw	0,0,0,0,0

	user_name	db 'user32.dll',0
	kernel_name	db 'kernel32.dll',0

	sMessageBox	db 0,0,'MessageBoxA',0
	sExitProcess	db 0,0,'ExitProcess',0

	align 8
	user_table:
	MessageBox	dd rva sMessageBox
			dd 0
	kernel_table:
	ExitProcess	dd rva sExitProcess
			dd 0
