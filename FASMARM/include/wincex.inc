
;Extended WinCE programming headers

	format	PE GUI

	include 'wince.inc'
	include 'macro\armlitrl.inc'

macro .code {section '.text' code readable executable}
macro .data {section '.data' data readable writeable}

macro .end begin {
	entry begin
	section '.idata' import readable writeable
	library coredll,'COREDLL.DLL'
	include	'apice\coredll.inc'
}

macro endp {
	literals
	endp
}
