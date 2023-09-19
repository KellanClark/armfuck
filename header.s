; Header template modified from jsmolka
; Uses ldm-only entry point method from zayd (but 8 bytes shorter and without a certain edge case)

format binary as 'gba'
processor 0xfe
coprocessor 0x0
org 0x8000000

include 'lib/macros.inc'

gba_header:
	; Branch to starting point (4 bytes)
	;ldmib pc, {pc} ; (unconditional branch to 0x0A82843D, a convenient value obtained from the nintendo logo)
	if defined MGBA ; mGBA only allows the first instruction to be a branch
		b 0x882843C
	else
		ldmib pc, {pc}
	end if

	; Nintendo logo (156 bytes)
	db	0x24,0xFF,0xAE,0x51,0x69,0x9A,0xA2,0x21,0x3D,0x84
	db	0x82,0x0A,0x84,0xE4,0x09,0xAD,0x11,0x24,0x8B,0x98
	db	0xC0,0x81,0x7F,0x21,0xA3,0x52,0xBE,0x19,0x93,0x09
	db	0xCE,0x20,0x10,0x46,0x4A,0x4A,0xF8,0x27,0x31,0xEC
	db	0x58,0xC7,0xE8,0x33,0x82,0xE3,0xCE,0xBF,0x85,0xF4
	db	0xDF,0x94,0xCE,0x4B,0x09,0xC1,0x94,0x56,0x8A,0xC0
	db	0x13,0x72,0xA7,0xFC,0x9F,0x84,0x4D,0x73,0xA3,0xCA
	db	0x9A,0x61,0x58,0x97,0xA3,0x27,0xFC,0x03,0x98,0x76
	db	0x23,0x1D,0xC7,0x61,0x03,0x04,0xAE,0x56,0xBF,0x38
	db	0x84,0x00,0x40,0xA7,0x0E,0xFD,0xFF,0x52,0xFE,0x03
	db	0x6F,0x95,0x30,0xF1,0x97,0xFB,0xC0,0x85,0x60,0xD6
	db	0x80,0x25,0xA9,0x63,0xBE,0x03,0x01,0x4E,0x38,0xE2
	db	0xF9,0xA2,0x34,0xFF,0xBB,0x3E,0x03,0x44,0x78,0x00
	db	0x90,0xCB,0x88,0x11,0x3A,0x94,0x65,0xC0,0x7C,0x63
	db	0x87,0xF0,0x3C,0xAF,0xD6,0x25,0xE4,0x8B,0x38,0x0A
	db	0xAC,0x72,0x21,0xD4,0xF8,0x07

	db	'armfuck',0,0,0,0,0 ; Game title (12 bytes)
	db	':3FU'		; Game code (4 bytes)
	db	'KC'		; Maker code (2 bytes)
	db	0x96		; Fixed (1 byte)
	db	0x00		; Unit code (1 byte)
	db	0x80		; Device type (1 byte)
	db	0,0,0,0,0,0,0	; Unused (7 bytes)
	db	0x00		; Game version (1 byte)
	db	0x52		; Complement (1 byte)
	db	0,0		; Reserved (2 bytes)

org 0x3000000
include 'interpreter.s'
org 0x80000C0 + INTERPRETER_SIZE

include 'tables/tilemap.s'
include 'tables/glyphs.s'
include 'tables/numbers.s'
include 'main.s'

input_start:
; Pad with "0" values until nintendo_logo is located at 0x882843C
times (0x882843C - (12 * 4) - $) / 4 dw number_table + 4

; Handler addresses so they can be obtained by a script
dw input_start
dw number_table
dw NUMBER_SIZE
dw command_right
dw command_left
dw command_inc
dw command_dec
dw command_out
dw command_in
dw command_open
dw command_close
dw command_halt

nintendo_logo:
	ldmdb pc, {pc}; (unconditional branch to main)
	dw main

brainfuck_start:
