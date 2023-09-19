; Assorted notes used while planning out the code
; They might not make sense and aren't guarenteed to be up to date

Variables:
working data - dat - r0
working pointer - ptr -r1
trash - tmp - r2 ; r3-r9 can also be used as trash registers
vram pointer - vram - r10
code pointer - cp - r11
data pointer - dp - r12
literal pool/pointer - r12 ; Only used in setup
normal stack - sp - r13
input stream pointer - input - r14 ; It's not like r14 is being used


Pools:
Glyphs - VRAM data for how the characters look
Number table - explained later
Literal pool - a list of easily-accessible constants used to set up the program


Setup:
1. Jump to the entrypoint of the program
2. Load literal pool pointer
3. Initialize EWRAM to "0"
4. Copy brainfuck interpreter into IWRAM
5. Initialize graphics registers
6. Initialize everything needed for the interpreter using the literal pool
7. Jump to start of interpreter


Macros:
inc rX - ldmia rX!, {tmp} - Increments a register by 4
dec rX - ldmda rX!, {tmp} - Decrements a register by 4
nopl - ldmia tmp, {tmp} - nop using ldm
call rX - stmdb sp!, {r15}/ldmia rX, {r15} - calls a subroutine with address at [rX] and pushes the return address to the stack
ret - ldmia sp!, {r15} - returns from subroutine
jump - ldmdb r15, {r15}/dw addr - Unconditional jump to an address
load - ldmia r15, {reg}/ldmia r15, {r15}/dw val/dw $ + 4 - Load an immmediate value into a register (literal pool prefered if possible)

; Executes the instruction at *ptr
macro execptr {
    ldmia ptr, {tmp\}
    stmib r15, {tmp\}
    nopl ; Empty pipeline
    nopl

    nopl ; To be replaced
}

;if *ptr then
;  goto op1
;else
;  goto op2
;
;Where:
; true/1 = ldmdb r15, {r15}
; false/2 = ldmia r15, {r15}
macro condjump op1, op2 {
    execptr
    ; ldmdb r15, {r15} ; Select option 1
    ; ldmia r15, {r15} ; Select option 2

    dw op1 ; Option 1
    dw op2 ; Option 2
}

;if *ptr then
;  dat = op1
;else
;  dat = op2
;
;Where:
; true/1 = ldmia r15, {dat}
; false/2 = ldmib r15, {dat}
macro select op1 op2 {
    execptr

    ; ldmia r15, {dat} ; Select option 1
    ; ldmib r15, {dat} ; Select option 2

    ldmib r15, {r15\} ; Skip to end
    dw ; Option 1
    dw ; Option 2
    dw $ + 4
}


Dispatch:
The "code" is just a list of constants containing the address of the handler. It's stored at the end of the ROM.
stmdb sp!, {r15} ; Push return address onto the stack
ldmia cp!, {r15} ; Jump to the handler
nop ; Just in case it pushes +8 instead of +12
; I think execution continues here


Commands:
Prefix - Every handler begins with this
dw ; offset stack level forward (ldmia dat!, {r3, r4, r5, r6}; nopl; ldmda dat!, {r3, r4, r5, r6})
dw ; offset stack level reverse
start:

'>' - increment data pointer - inc dp
'<' - decrement data pointer - dec dp
;'+' - increment data - ldmia cp, {dat}; inc dat; stmia cp, {dat}
;'-' - decrement data - ldmia cp, {dat}; dec dat; stmia cp, {dat}

'[' - if nonzero, loop until ']' -
; Adjust the stack level by Executing the instruction at [[cp]+4]
ldmia cp!, {dat} ; dat = [cp]
ldmib dat, {tmp} ; tmp = [[cp]+4]
stmdb r15!, {tmp} ; repace the nop with tmp and refill the pipeline
nopl ; to be replaced

{ ; [
	; End if value isn't 0
	ldmia dp, {ptr}
	inc ptr ; Point at zeroSel
	condjump .cont .end

.cont:
	load sl 1
.loop:
    ; Apply the instruction's stack level offset
    ldmia cp!, {ptr}
    dec ptr
    dec ptr
    execptr

    ; if sl == 0: break;
	ldmia sl, {ptr}
	inc ptr ; Point at zeroSel
	condjump .end .loop

.end:
    ret
}

{ ; ']'
	; End if value is 0
	ldmia dp, {ptr}
	inc ptr ; Point at zeroSel
	condjump .end .cont

.cont:
	load sl 1
	dec cp
.loop:
    ; Apply the instruction's stack level offset
    ldmdb cp!, {ptr}
    dec ptr
    execptr

	; if sl == 0: break;
	ldmia sl, {ptr}
	inc ptr ; Point at zeroSel
	condjump .end .loop

.end:
	ret
}

'.' - Output the current cell as an ASCII character -
glyphtmp = glyph
vramtmp = vram
rep 8 {
	dat1 = *(glyphtmp)
	dat2 = *(glyphtmp + 4)
	glyphtmp += 8

	*(vramtmp) = dat1
	*(vramtmp + 4) = dat2
	vramtmp += 240
}
vram += 8

Halt - Ends the program -
ldmdb r15, {r15}
dw $ - 4


Numbers:
Cells are unsigned values ranging from 0 to 255
A number is represented by an pointer to an entry in the "number table"
Each number table entry is 16 bytes: Usually 4 for a pointer to itself and 12 for other data associated with the number
There are 256 entries representing the range of valid numbers and an extra entry on each end with different self pointers to provide wrapping
The entry for 0 is also differentiated with the zeroSel field so the '[' and ']' commands can check for the number

struct Number {
	Number *self;
	bool zeroSel; ; true means it is 0
	Glyph *glyph;
	u32 extra;
};

dw $ + (256 * 8) ; -1 -> 255
ldmia r15, {r15}
dw 0,0
dw $ ; 0
ldmdb r15, {r15}
dw glyphs_start
dw 0
rept 255 { ; 1 through 255
    dw $
    ldmia r15, {r15}
    dw 0,0
}
dw $ - (256 * 8) ; 256 -> 0
ldmdb r15, {r15}
dw 0,0
