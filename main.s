literal_pool:
dw MEM_EWRAM ; Set EWRAM start location
rept 8 {
	dw number_table + 4 ; Set EWRAM value
}

dw 0x80000C0 ; Interpreter copy source
dw MEM_IWRAM ; Interpreter copy destination

dw tilemap_start ; Tilemap copy source
dw MEM_VRAM + (0x800 * 31) ; Tilemap copy destination (screenblock 31)

dw REG_DISPCNT
dw DISPCNT_BGMODE0 or DISPCNT_DISPLAY_BG0 ; DISPCNT value
dw REG_BG0CNT
dw BGCNT_CB0 or BGCNT_SB31 ; BG0CNT value
dw MEM_PALETTE
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

	; 5. Copy tilemap into VRAM
	ldmia lp!, {r0, r1}
	rept ((256 / 8) * (160 / 8)) / 16 {
		ldmia r0!, {tmp-tmp8\}
		stmia r1!, {tmp-tmp8\}
	}

	; 6. Initialize graphics registers
	ldmia lp!, {r0-r5}
	stmia r0, {r1} ; Set DISPCNT
	stmia r2, {r3} ; Set BG0CNT
	stmia r4, {r5} ; Set the palette

	; 7. Initialize registers for the interpreter
	; 8. Jump to start of interpreter
	ldmia lp, {vram, cp, dp, input, pc}
