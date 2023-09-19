; Macros for using the linked list number system

; Increments the number in reg
macro num_inc reg {
	ldmdb reg, {reg\} ; reg = reg->next
}

; Decrements the number in reg
macro num_dec reg {
	ldmia reg, {reg\} ; reg = reg->prev
}

; Macro for generating a table entry
NUMBER_SIZE equ 16
macro number val {
	; next
	if val = 255
		dw $ - (255 * NUMBER_SIZE) + 4 ; Point to 0
	else
		dw $ + NUMBER_SIZE + 4
	end if

	; prev
	if val = 0
		dw $ - (255 * NUMBER_SIZE)
	else
		dw $ - NUMBER_SIZE
	end if

	; isZero
	if val = 0
		ldmdb r15, {r15\} ; true
	else
		ldmia r15, {r15\} ; false
	end if

	; glyphPtr
	dw glyphs_start + (val * 32)
}
