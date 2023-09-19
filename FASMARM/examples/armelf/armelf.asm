	format ELF executable
	entry start

	segment readable executable

start:	mov	r0,0
	add	r1,pc,hello-$-8
	mov	r2,hello_len
	swi	0x900004
	mov	r0,6
	swi	0x900001

hello:	db	'Hello world',10
hello_len=$-hello

	;dummy section for bss, see http://board.flatassembler.net/topic.php?t=3689
	segment writeable
