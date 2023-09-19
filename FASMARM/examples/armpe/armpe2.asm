
; Example of building a WinCE executable using medium level macros

	include	'wince.inc'
	format	PE GUI
	entry	Start

section '.text' code readable executable

proc Start uses[lr]
	apscall	MessageBoxW,0,addr Text,addr Caption,0
	ret
endp

Caption	du	'ARM example MLI macros',0
Text	du	'Hello ArmCE world',0

section '.idata' import readable writeable

	library coredll,'COREDLL.DLL'
	include	'apice\coredll.inc'
