literal_pool:
dw MEM_EWRAM ; Set EWRAM start location
rept 8 {
	dw number_table + 4 ; Set EWRAM value
}

dw 0x80000C0 ; Interpreter copy source
dw MEM_IWRAM ; Interpreter copy destination

dw REG_DISPCNT
dw MEM_PALETTE
dw DISPCNT_BGMODE4 or DISPCNT_DISPLAY_BG2 ; DISPCNT value
dw 0xFFFF0000 ; Palette value

dw MEM_VRAM ; Initial vram
dw brainfuck_start ; Initial cp
dw MEM_EWRAM + 0x0800000 ; Initial dp (starts in the middle of mirrors to allow a little bit of wrapping)
dw input_start ; Initial input
dw interpreter_start ; Initial pc

main:
	; 2. Load the literal pool pointer
	load lp, literal_pool

	; 3. Clear EWRAM
	ldmia lp!, {r1, tmp-tmp8}
	rept (256 * 1024) / 32 { ; Set 256k bytes
		stmia r1!, {tmp-tmp8\}
	}

	; 4. Copy brainfuck interpreter into IWRAM
	ldmia lp!, {r0, r1}
	rept 1024 / 32 { ; Copy 1k bytes
		ldmia r0!, {tmp-tmp8\}
		stmia r1!, {tmp-tmp8\}
	}

	; 5. Initialize graphics registers
	ldmia lp!, {r0-r3}
	stmia r0, {r2} ; Set DISPCNT
	stmia r1, {r3} ; Set the palette

	; 6. Initialize registers for the interpreter
	; 7. Jump to start of interpreter
	ldmia lp, {vram, cp, dp, input, pc}
