interpreter_start:
	stmdb sp!, {r15} ; Push return address onto the stack
	ldmia cp!, {r15} ; Jump to the handler
	inc cp ; Move to the next instruction
	; TODO: Insert more stuff? Is there anything else I need in the main loop of a Brainfuck interpreter?
	ldmdb r15, {r15} ; Jump to beginning of loop
	dw interpreter_start

; Increment data pointer
	nopl
	nopl
command_right:
	; dp += 4
	inc dp
loop_end: ; Reusing the ret here saves a whole 8 bytes
	ret

; Decrement data pointer
	nopl
	nopl
command_left:
	; dp -= 4
	dec dp
	ret


; Increment the current number
	nopl
	nopl
command_inc:
	; *dp += 1
	ldmia dp, {dat}
	num_inc dat
	stmia dp, {dat}
	ret


; Decrement the current number
	nopl
	nopl
command_dec:
	; *dp -= 1
	ldmia dp, {dat}
	num_dec dat
	stmia dp, {dat}
	ret


; Print the current number as an ASCII character
; Stupid hack that fails when I hit the end of a line. I wish tiles were 4 bytes instead of 2
; Even with that, newlines would be a pain in the ass to implement.
	nopl
	nopl
command_out:
	; putchar(*dp)
	ldmia dp, {dat} ; ptr = *(*dp + 8)
	ldmia dat!, {tmp, r3}
	ldmia dat, {ptr}
	stmdb sp!, {vram} ; dat = tmp vram
	ldmia sp!, {dat}
	rept 8 {
		; Copy 2 words from the glyph to vram
		ldmia ptr!, {r3, r4\}
		stmia dat!, {r3, r4\}

		; dat += 240 - 8
		ldmia dat!, {tmp, r3, r4, r5, r6, r7, r8, r9\}
		ldmia dat!, {tmp, r3, r4, r5, r6, r7, r8, r9\}
		ldmia dat!, {tmp, r3, r4, r5, r6, r7, r8, r9\}
		ldmia dat!, {tmp, r3, r4, r5, r6, r7, r8, r9\}
		ldmia dat!, {tmp, r3, r4, r5, r6, r7, r8, r9\}
		ldmia dat!, {tmp, r3, r4, r5, r6, r7, r8, r9\}
		ldmia dat!, {tmp, r3, r4, r5, r6, r7, r8, r9\}
		ldmia dat!, {tmp, r3\}
	}
	ldmia vram!, {tmp, r3} ; vram += 8

	ret


; Sets the current number to the next input character
	nopl
	nopl
command_in:
	; *dp = getchar()
	ldmia input!, {dat}
	stmia dp, {dat}
	ret


; I hate myself. Half of the design decisions were made because of these two instructions. It's my LDM/STM.
; I won't even bother to optimize them right now.
	num_inc dat ; Increment stack level
	num_dec dat ; Decrement stack level
command_open:
	; End if value isn't 0
	ldmia dp, {ptr}
	inc ptr ; Point at isZero
	condjump open_cont, loop_end
open_cont:
	load dat, number_table + NUMBER_SIZE + 4 ; dat = 1
open_loop:
    ; Apply the instruction's stack level offset
    ldmia cp!, {ptr}
    dec ptr
    dec ptr
    execptr

    ; if dat == 0: break;
	;ldmia dat, {ptr}
	;inc ptr ; Point at isZero
	;condjump loop_end, open_loop
	ldmib dat, {tmp}
    stmib r15, {tmp}
    nopl
    nopl
    nopl ; Will be replaced
    dw loop_end
    dw open_loop


	num_dec dat ; Decrement stack level
	num_inc dat ; Increment stack level
command_close:
	; End if value is 0
	ldmia dp, {ptr}
	inc ptr ; Point at isZero
	condjump loop_end, close_cont
close_cont:
	load dat, number_table + NUMBER_SIZE + 4 ; dat = 1
	dec cp
close_loop:
    ; Apply the instruction's stack level offset
    ldmdb cp!, {ptr}
    dec ptr
    execptr

	; if sl == 0: break;
	;ldmia dat, {ptr}
	;inc ptr ; Point at isZero
	;condjump loop_end, close_loop
	ldmib dat, {tmp}
    stmib r15, {tmp}
    nopl
    nopl
    nopl ; Will be replaced
    dw loop_end
    dw close_loop


; Marks the end of the program so it doesn't go past the end executing garbage code for eternity
command_halt: ; This will never be in the middle of a loop, so it doesn't need the prefix
	; Put the system into stop mode if it's even allowed outside the BIOS
	dw 0xE89F8003 ; ldmia r15, {dat, ptr, r15}
	dw 0
	dw 0x8000
	dw REG_HALTCNT - 1
	dw $ + 4

	; Loop infinitely
	ldmdb r15, {r15}
	dw $ - 4


; Pad to a nice even number because the start and end addresses are hardcoded and I'm lazy
INTERPRETER_SIZE equ 1024
rb INTERPRETER_SIZE - ($ - interpreter_start)
