include 'constants.inc'
include 'number_macros.inc'

; Register Aliasas
dat equ r0
dat! equ r0!
ptr equ r1
ptr! equ r1!
tmp equ r2
tmp! equ r2!
tmp2 equ r3
tmp2! equ r3!
tmp3 equ r4
tmp3! equ r4!
tmp4 equ r5
tmp4! equ r5!
tmp5 equ r6
tmp5! equ r6!
tmp6 equ r7
tmp6! equ r7!
tmp7 equ r8
tmp7! equ r8!
tmp8 equ r9
tmp8! equ r9!
vram equ r10
vram! equ r10!
cp equ r11
cp! equ r11!
dp equ r12
dp! equ r12!
lp equ r12
lp! equ r12!
input equ r14
input! equ r14!

; nop using ldm
macro nopl {
	ldmia tmp, {tmp\}
}

; Increments a register by 4
macro inc reg {
	ldmia reg#!, {tmp\}
}

; Decrements a register by 4
macro dec reg {
	ldmda reg#!, {tmp\}
}

; Returns from the subroutine
macro ret {
	ldmia sp!, {r15\}
}

; Load an immmediate value into a register (literal pool prefered if possible)
; Credit to Zayd for helping me shorten this by an instruction. Unfortunately fasm doesn't want to let me have fun ~~fasm more like fascist~~
macro load reg, val {
	;ldmda r15, {reg, r15\}
	ldmia r15, {reg\}
	ldmia r15, {r15\}
	dw val
	dw $ + 4
}

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
