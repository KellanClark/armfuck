
; Example of building a WinCE executable using high level macros

	include	'wincex.inc'

.code

proc Start uses [lr]
	apscall	MessageBoxW,0,*'Hello ArmCE world',*'ARM example HLI macros',0
	ret
endp

.end Start
