; Pascal Microengine microcode, MICROMs CP2171-14, CP2171-15, CP2171-18
; Reverse-engineered source code
; Copyright 2015, 2016 Eric Smith <spacewar@gmail.com>

; Reverse-engineering in progress:
;   There are probably many errors.
;   There is no existing assembler that can assemble this file as-is.

; Note that there are jumps and subroutine returns that occur on
; microinstructions that aren't explicit flow control instructions, due
; to the translation PLAs in the control chip.

; Array 1, the AND plane of the first PLA determines the addresses at which
; translations occur. Array 2, the corresponding OR plane, determines which
; translation occurs at that location.  These are shown by comments in this
; source code, of the form:
;			; 007: translation 6b (row 11)
; or, where the translation is effectively being called as a subroutine
; (through the use of the "lrr" bit of the instruction):
;			; 034: translation 1f subr (row 39)
;                          ^               ^            ^
;                          |               |            |
;     address -------------+               |            |
;                                          |            |
;     translation number ------------------+            |
;                                                       |
;     row number in arrays 1 and 2 ---------------------+

; Arrays 3 and 4, the AND and OR plane of the second PLA, respectively,
; take the translation number, two bits of the translation state register,
; one byte of the translation register, and one byte of the interrupt
; register, and perform some combination of loading a new value into the
; PC from array 4 or the subroutine return register, and/or loading a new
; value into the translation state register.

; The branch targets of the translations (ouputs of array 4, the OR
; plane of the second PLA) are designated here by labels of the form
; tt_nn, where nn is row number of array 4.  There are no labels
; tt_14, tt_98, and tt_99, because rows 98 and 99 are unused, and row
; 14 causes a subroutine return rather than a jump to a fixed address.

; Note that ",rsvc" at the end of an instruction asserts the RNI signal
; going into array 1 and 2, which results in translation 3e happening on
; the *next* microinstruction.


; register assignments:

;                   LPR/SPR
; direct  indirect  reg#     name        description
; ------  --------  -------  ----------  --------------------------------
; rb:a               7       PC (IPC)    instruction program counter
; rd:c    g=6        4       SP          stack pointer
; rf:e    g=7        5       MP          mark stack pointer

;         g=0                ?
;         g=1       -1       CTP         current task pointer (active TIB)
;         g=2       -2       SSV (SDP)   segment dict pointer
;         g=3       -3       RQ (RQP)    ready queue pointer
;         g=4                SEGB (SGP)  current segment pointer
;         g=5                BP          mark stack base pointer


	org	0x000

	jmp	unimplemented_instruction


  	jmp	reset		; cold start (addr 0x001)


; from translation 1f, if TSR = X0, and loads TSR := 0
tt_95:	riw1	ipch,ipcl	; r9:8, tr := [ipc++]; load ics
	iw	0x3,r8

	mbf	r8,r6
	ll	0x0,r7		; 005: translation 6b (row 11)


; from translation 1f, if TSR = X1, and loads TSR := 2
tt_96:	mbf	r9,r6
L007:	ll	0x0,r7		; 007: translation 6b (row 11)


; from translation 7a, if TSR = X0, and loads TSR := 0
tt_93:	riw1	ipch,ipcl	; r9:8, tr := [ipc++]; load ics
	iw	0x3,r8

	mbf	r8,r6		; r6 := r8, update flags
	jnf	L007		; if 0x00..0x7f, go to L007

	nl	0x7f,r8		; mask off MSB
	mb	r8,r7
	mb	r9,r6		; 00e: translation 6e (row 14)


; from translation 7a, if TSR = X1, and loads TSR := 2
tt_94:	mbf	r9,r6
	jnf	L007

	nl	0x7f,r9
	mb	r9,r7

	riw1	ipch,ipcl	; r9:8, tr := [ipc++]; load ics
	iw	0x3,r8

	mb	r8,r6
	rtsr			; reset translation state ; 016: translation 6b (row 00)
	

; from end of instruction (translation 3e),
; if no interrupt, and translation state = X0
tt_04:	riw1	ipch,ipcl	; r9:8, tr := [ipc++]; load ics
	iw	0x3,r8

	mb	r8,r6,,1	; 019: translation 3d (row 19)
	jmp	L600		; if no translation occured, undefined opcode


; from end of instruction (translation 3e),
; if no interrupt, and translation state = 01
tt_06:	r	r9,r8		; r9:8, tr := [r9:8]; load ics
	iw	0x3,r8

; from end of instruction (translation 3e),
; if no interrupt, and translation state = 11
tt_05:	mb	r9,r6,,1	; 01d: translation 3d (row 19)
	jmp	L600		; if no translation occured, undefined opcode


; from translation 76, if TSR = X0, and loads TSR := 2
tt_91:	riw1	ipch,ipcl	; r7:6 := [ipc++]
	iw	0x0,r6		; 020: translation 6b (row 12)


; from translation 76, if TSR = X1, and loads TSR := 0
tt_92:	mb	r9,r6

	riw1	ipch,ipcl	; r9:8, tr := [ipc++]; load ics
	iw	0x3,r8

	mb	r8,r7		; 024: translation 6b (row 12)


; opcode 0xc0..0xdf (from translation 3d)
tt_56:	riw1	sph,spl		; r3:2 := [sp++]
	iwf	0x0,r2		; 026: translation 3b (row 20)


	riw1	sph,spl		; r5:4 := [sp++]
	iwf	0x0,r4		; 028: translation 37 (row 22)


	r	sph,spl		; r7:6 := [sp]
	iwf	0x0,r6		; 02a: translation 2f (row 24)



tt_37:	; opcode 0xa0..0xa7, 0xb0..0xb7 (from translation 3d)
tt_54:	; opcode 0xb8..0xbf (from translation 3d)
	riw1	sph,spl		; r3:2 := [sp++]
	iwf	0x0,r2		; 02c: translation 3b (row 21)


; opcode 0xe0..0xe7 (from translation 3d)
tt_82:	r	sph,spl		; r7:6 := [sp]
	iwf	0x0,r6		; 02e: translation 37 (row 23)


	nop


L030:	nop			; 030: translation 7a (row 26)



; opcode 0x00..0x1f: SLDCi - Short Load Word Constant (from translation 3d)
tt_16:
L031:	dw1	spl,spl
	w	sph,spl,rsvc
	ob	r6,r6

	
; opcode 0x80: LDCB - LoaD Constant Byte (from translation 3d)
tt_20:	dw1	spl,spl,lrr	; 034: translation 1f subr (row 39)
	w	sph,spl,rsvc
	ow	r7,r6

	
; opcode 0x81: LDCI - LoaD Constant Immediate (from translation 3d)
tt_21:	dw1	spl,spl,lrr	; 037: translation 76 subr (row 53)
	w	sph,spl,rsvc
	ow	r7,r6


; opcode 0x98: LDCN - LoaD Constant Nil
op_ldcn:
	ll	0xfc,r7		; r7:6 := 0xfc00 (Nil)
	ll	0x0,r6

	dw1	spl,spl		; 03c: translation 5d (row 55) - write one word to stack and end instruction


; opcode 0x20..0x2f: SLDLi - Short Local Local Word (from translation 3d)
tt_17:	ll	0x0,r7
	al	0xe1,r6

	aw	mpl,r6		; 03f: translation 73 (row 70)


; opcode 0x87: LDL - Load Local Word (from translation 3d)
tt_27:	nop	,lrr		; 040: translation 7a subr (row 35)
	aw	mpl,r6		; 041: translation 73 (row 72, 73)


; opcode 0x30..0x3f: SLDOi - Short Load Global Word (from translation 3d)
tt_18:	ll	0x0,r7
	al	0xd1,r6
	ll	0x5,r4
	lgl	r4
	aw	gl,r6		; 046: translation 73 (row 71)


; opcode 0x85: LDO - Load Global Word (from translation 3d)
tt_25:	ll	0x5,r4
	lgl	r4,lrr		; 048: translation 7a subr (row 35)
	aw	gl,r6		; 049: translation 73 (row 72, 74)


; opcode 0x89: LOD - LOaD intermediate word (from translation 3d)
tt_29:	mw	mpl,r4,lrr	; 04a: translation 1f subr (row 40)
	jzf	L0d3,lrr
	jsr	L030
	aw	r4,r6		; 04d: translation 73 (row 74)


; opcode 0x9a: LDE - LoaD word Extended
op_lde:	jsr	L0c6
	jsr	L2ba
	jsr	L030
	aw	r2,r6		; 051: translation 73 (row 73)


; opcode 0x82: LCA - Load Constant Address (from translation 3d)
tt_22:	ll	0x4,r4
	lgl	r4,lrr		; 053: translation 7a subr (row 36)
	aw	gl,r6
	dw1	spl,spl		; 055: translation 5d (row 56) - write one word to stack and end instruction


; opcode 0x84: LLA - Load Local Address (from translation 3d)
tt_24:	nop	,lrr		; 056: translation 7a subr (row 27)
	aw	mpl,r6
	dw1	spl,spl		; 058: translation 5d (row 64) - write one word to stack and end instruction


; opcode 0x86: LAO - Load Global Address (from translation 3d)
tt_26:	ll	0x5,r4
	lgl	r4,lrr		; 05a: translation 7a subr (row 28)
	aw	gl,r6
	dw1	spl,spl		; 05c: translation 5d (row 64) - write one word to stack and end instruction


; opcode 0x88: LDA - Load Intermediate Address (from translation 3d)
tt_28:	mw	mpl,r4,lrr	; 05d: translation 1f subr (row 41)
	jzf	L0d3,lrr

	jsr	L030
	aw	r4,r6
	dw1	spl,spl		; 061: translation 5d (row 65) - write one word to stack and end instruction


; opcode 0x9b: LAE - Load Address Extended
op_lae:	jsr	L0c6
	jsr	L2ba
	jsr	L030
	aw	r2,r6
	dw1	spl,spl		; 066: translation 5d (row 57) - write one word to stack and end instruction


; opcode 0xa4: STL - STore Local word (from translation 3b)
tt_42:	nop	,lrr		; 067: translation 7a subr (row 29)
	aw	mpl,r6		; [mpl+r7:6] := r3:2
	w	r7,r6,rsvc
	ow	r3,r2


; opcode 0xa5: SRO - Store global word (from translation 3b)
tt_43:	ll	0x5,r4		; [bp+r7:6] := r3:2
	lgl	r4,lrr		; 06c: translation 7a subr (row 30)
	aw	gl,r6
	w	r7,r6,rsvc
	ow	r3,r2


; opcode 0xa6: STR - SToRe intermediate word (from translation 3b)
tt_44:	mw	mpl,r4,lrr	; 070: translation 1f subr (row 42)
	jzf	L0d3,lrr
	jsr	L030
	aw	r6,r4

; opcode 0xc4: STO - STOre indirect (from translation 37)
tt_61:	w	r5,r4,rsvc
	ow	r3,r2


; opcode 0xd9: STE - STore word Extended
op_ste:	mw	r2,r4,lrr	; 076: translation 1f subr (row 43)
	jsr	L2ba
	jsr	L030
	aw	r2,r6
	w	r7,r6,rsvc
	ow	r5,r4


; opcode 0xa7: LDB - Load Byte (from translation 37)
tt_45:	slbf	r3,r8
	srwcf	r3,r3
	aw	r6,r2
	r	r3,r2
	iw	0x0,r6
	cmb	r7,r6
	w	sph,spl,rsvc
	ob	r6,r6


; opcode 0xc8: STB - STore Byte (from translation 37)
tt_65:	riw1	sph,spl
	iw	0x0,r6
	slbf	r5,r8
	srwcf	r5,r5
	aw	r6,r4

	r	r5,r4
	iw	0x4,r6
	cmb	r2,r7
	cmb	r6,r2,rsvc
	ow	r7,r2


	nop


; opcode 0xc9: LDP - LoaD a Packed field (from translation 2f)
tt_66:	mb	r4,r8
	mbf	r2,r4
	r	r7,r6
	iw	0x0,r2
	jzt	L097
L094:	srw	r3,r3
	db1	r4,r4
	jzbf	L094
L097:	jsr	L1d7
	nw	r2,r6		; 098: translation 5d (row 58) - write one word to stack and end instruction


; opcode 0xca: STP - STore into a Packed field (from translation 37)
tt_67:	riw1	sph,spl
	ib	0x1,r8
	jsr	L1d7
	mbf	r4,r4
	jzt	L0a2
L09e:	slw	r2,r2
	slw	r6,r6
	db1	r4,r4
	jzbf	L09e
L0a2:	lgl	r4
	riw1	sph,spl
	iw	0x0,r4
	nw	r6,r2

	r	r5,r4
	iw	0x4,gl
	ncw	r6,gl
	orw	r2,gl,rsvc
	ow	gh,gl


; opcode 0x83: LDC - load multiple word constant (from translation 3d)
tt_23:	ll	0x4,r4
	lgl	r4,lrr		; 0ac: translation 7a subr (row 31)
	aw	gl,r6
	mw	r6,r2

; opcode 0xd0: LDM - LoaD Multiple words (from translation 3b)
tt_73:	jsr	L0c6
	sw	r6,spl
	mw	spl,r4
L0b2:	ll	0x0,r8
	lgl	r8
	jzt	L0bb
L0b5:	riw1	r3,r2
	iw	0x0,gl
	wiw1	r5,r4
	ow	gh,gl
	dw1f	r6,r6
	jzf	L0b5
L0bb:	nop			; 0bb: translation 3e (row 75) - end of instruction


; opcode 0x8e: STM - STore Multiple words (from translation 3d)
tt_34:	mw	spl,r2,lrr	; 0bc: translation 1f subr (row 44)
	aw	r6,spl
	riw1	sph,spl
	iw	0x0,r4
	jmp	L0b2


; opcode 0xc5: MOV - MOVe words (from translation 37)
tt_62:	jsr	L030
	jmp	L0b2


; opcode 0x92: CPI - Call Procedure Intermediate
op_cpi:	mw	mpl,r4,lrr	; 0c3: translation 1f subr (row 45)
	jzf	L0d3,lrr
	jmp	L2a2


; fetch a byte operand?
L0c6:	nop			; 0c3: translation 1f (row 46)


; opcode 0x95: CXI - Call eXternal procedure Intermediate
op_cxi:	jsr	L0c6
	mw	r6,r2
	mw	mpl,r4,lrr	; 0c9: translation 1f subr (row 47)
	jzf	L0d3,lrr
	jmp	L298


; opcode 0x99: LSL - Load Static Link
op_lsl:	mw	mpl,r4,lrr	; lm := mp	; 0cc: translation 1f subr (row 48)
	jzf	L0d3,lrr	; for i := 1 to DB do
	al	0xfd,r4		; lm := lm^.m.msstat
	cdb	r5
	dw1	spl,spl		; sp := sp - 1
	w	sph,spl,rsvc	; sp^.p := lm
	ow	r5,r4

L0d3:	al	0xfd,r4
	cdb	r5

L0d5:	r	r5,r4
	iw	0x0,r4
	db1	r6,r6
	jzbf	L0d5

	al	0x3,r4
	cib	r5		; 0da: translation 6b (row 01)


; opcode 0x78..0x7f: SINDi - Short INDex and load word (from translation 3d)
tt_19:	r	sph,spl
	iw	0x0,r2

	nl	0x7,r6
	ab	r6,r2
	cib	r3

	r	r3,r2
	iw	0x0,r6		; 0e1: translation 5d (row 65, 66) - write one word to stack and end instruction


; opcode 0xe6: IND - INDex and load word (from translation 37)
tt_89:	mw	r6,r2,lrr	; 0e2: translation 7a subr (row 37)
	aw	r6,r2
	r	r3,r2
	iw	0x0,r6		; 0e5: translation 5d (row 66, 67) - write one word to stack and end instruction


; opcode 0xe7: INC - INCrement field pointer (from translation 37)
tt_90:	mw	r6,r2,lrr	; 0e6: translation 7a subr (row 37)
	aw	r2,r6		; 0e7: translation 5d (row 67) - write one word to stack and end instruction


; opcode 0xd7: IXA: IndeX Array (from translation 3b)
tt_80:	jzt	L0fd
	mw	r2,r4,lrr	; 0e9: translation 7a subr (row 32)
	jsr	L12e

	r	sph,spl
	iw	0x4,r4
	aw	r4,r2,rsvc
	ow	r3,r2


; opcode 0xd8: IXP - IndeX Packed array
op_ixp:	jsr	L0c6
	jsr	L14b

	r	sph,spl
	iw	0x4,r6
	aw	r2,r6
	ow	r7,r6

	dw1	spl,spl,lrr	; 0f5: translation 1f subr (row 49)
	w	sph,spl
	ow	r7,r6
	mwf	r4,r2
	jzt	L0fb
	jsr	L12e
L0fb:	dw1	spl,spl
	jmp	L107


L0fd:	jsr	L030
	jmp	op_nop


; opcode 0xe0: ABI - ABsolute value Integer (from translation 37)
tt_83:	jnf	L189


; opcode 0xe1: NGI - NeGate Integer (from translation 37)
tt_84:	tcw	r6,r6		; 100: translation 5d (row 68, 69) - write one word to stack and end instruction


; opcode 0xe3: ABR - ABsolute value Real (from translation 37)
tt_86:	nl	0x7f,r7		; 101: translation 5d (row 68, 69) - write one word to stack and end instruction


; opcode 0xe4: NGR - NeGate Real (from translation 37)
tt_87:	al	0x80,r7		; 102: translation 5d (row 68) - write one word to stack and end instruction


; opcode 0xa1: LAND - Logical AND (from translation 37)
tt_39:	nw	r2,r6		; 103: translation 5d (row 68) - write one word to stack and end instruction


; opcode 0xa0: LOR - Logical OR (from translation 37)
tt_38:	orw	r2,r6		; 104: translation 5d (row 69) - write one word to stack and end instruction


; opcode 0xe5: LNOT - Logical NOT (from translation 37)
tt_88:	ocw	r6,r6		; 105: translation 5d (row 69) - write one word to stack and end instruction


; opcode 0xa2: ADI - ADd Integer (from translation 37)
tt_40:	awf	r6,r2
L107:	w	sph,spl,rsvc
	ow	r3,r2


; opcode 0xa3: SBI - SuBtract Integer (from translation 37)
tt_41:	swf	r2,r6
	w	sph,spl,rsvc
	ow	r7,r6


; opcode 0x8c: MPI - MultiPly integers (from translation 3d)
tt_32:	riw1	sph,spl
	iwf	0x0,r6
	jzt	L164
	ll	0x0,r8
	jnf	L113
	tcw	r6,r6
	ll	0x1,r8
L113:	r	sph,spl
	iwf	0x0,r4
	jzt	L189
	jnf	L119
	tcw	r4,r4
	ocb	r8,r8
L119:	jsr	L12e
	srbf	r8,r8
L11b:	jcf	L107
	tcw	r2,r4

; push r5:r4 as instruction result, and dispatch next instruction
L11d:	w	sph,spl,rsvc
	ow	r5,r4


; opcode 0x8d: DVI - DiVide Integers (from translation 3d)
tt_33:	jsr	L13e
	jmp	L11b


; opcode 0x8f: MODI - MODulo Integers (from translation 3d)
tt_35:	jsr	L14f
	jcf	L11d
	jmp	L166


; opcode 0xcb: CHK - CHecK against subrange bounds (from translation 2f)
tt_68:	cwf	r6,r2
	jvf	L127
	mbf	r3,r3
L127:	jnt	range_error
	cwf	r4,r6
	jvf	L12b
	mbf	r7,r7
L12b:	jnf	L189

range_error:
	ll	0x1,r6		; raise exception 1 - invalid index or value out of range
	jmp	raise_exception


L12e:	xw	r2,r2
	cwf	r4,r6
	jnf	L139
	jmp	L133

L132:	slw	r4,r4
L133:	srwf	r7,r7
	jcf	L132
	aw	r4,r2
	jzf	L132
	rfs


L138:	slw	r6,r6
L139:	srwf	r5,r5
	jcf	L138
	aw	r6,r2
	jzf	L138
	rfs


L13e:	riw1	sph,spl		; r7:6 := [sp++]
	iwf	0x0,r6

	jzt	divide_by_zero

L141:	mb	r7,r8
	jnf	L144

	tcw	r6,r6

L144:	r	sph,spl		; r3:2 := [sp++]
	iwf	0x0,r2

	jzt	L189

	jnf	L14a
	
	xb	r3,r8
	tcw	r2,r2

L14a:	slbf	r8,r8
L14b:	cw	r6,r2
	jc8t	L154
	mw	r2,r4
	xw	r2,r2		; 14e: translation 6b (row 02)


L14f:	riw1	sph,spl		; r7:6 := [sp++]
	iwf	0x0,r6
	jzt	range_error
	jnf	L141
	jmp	range_error

L154:	xw	r4,r4		; r5:4 := 0
	ll	0x10,r8
	lgl	r4		; g := 0
	tcw	r6,gl
	dw1	r6,r6
	slwcf	r2,r2
L15a:	slwc	r4,r4
	cwf	r4,r6
	cawf	gl,r4
	slwcf	r2,r2
	db1	r8,r8
	jzbf	L15a
	icw1	r6,r6		; 160: translation 6b (row 03)


; from translation 73, unconditional
tt_15:	r	r7,r6
	iw	0x0,r6

; opcode 0xe2: DUP1 - DUPlicate 1 word of stack (from translation 37)
tt_85:
L163:	dw1	spl,spl

; write one word result to stack and end instruction
; translation 5d (row 97) jumps here
tt_97:
L164:	w	sph,spl,rsvc
	ow	r7,r6


L166:	sw	r4,r6
	jmp	L164


divide_by_zero:
	ll	0x6,r6		; raise exception 6 - divide by zero
	jmp	raise_exception


; opcode 0xc7: ADJ - ADJust set (from translation 3b)
tt_64:	mw	spl,r4
	aw	r2,spl,lrr	; 16b: translation 1f subr (row 50)
	cwf	r2,r6
	jnf	L178
	aw	r6,r4
L16f:	dw1	r4,r4
	r	r5,r4
	iw	0x0,r2
	dw1	spl,spl
	w	sph,spl
	ow	r3,r2
	dw1	r6,r6
	jzbf	L16f
	jmp	op_nop


L178:	sw	r6,spl
	jzt	L189
	sb	r2,r6
	mbf	r2,r7
	lgl	r3
	mw	spl,r2
	jzt	L185
L17f:	riw1	r5,r4
	iw	0x0,gl
	wiw1	r3,r2
	ow	gh,gl
	db1	r7,r7
	jzbf	L17f
L185:	wiw1	r3,r2
	ow	r7,r7
	db1	r6,r6
	jzbf	L185
L189:	jmp	op_nop


; opcode 0xbc: SRS  - build SubRange Set
op_srs:
	mb	r3,r8		; r3:2 and r7:6 must both be positive
	orbf	r7,r8
	jnt	range_error

	ll	0xf,r5		; r5:4 := 4079 (max set size)
	ll	0xef,r4

	cwf	r2,r4		; r3:2 must be less than or equal to max set size
	jnt	range_error

	cwf	r6,r4		; r7:6 must be less than or equal to max set size
	jnt	range_error

	xw	r4,r4		; r5:4 := 0

	cwf	r6,r2		; lo > hi
	jnt	L11d		;   yes, push zero result (null set)

	mw	r6,r4

	jsr	L1d1

	icb1	r6,r8

	jsr	L1d7

	mb	r2,r8
	mw	r4,r2
	mw	r6,r4

	jsr	L1d1

	mb	r8,r3
	mb	r6,r8

	jsr	L1d7

	ocw	r6,r6
	icb1	r3,r8
	sb	r2,r3
	jzbf	L1a7

	nw	r4,r6
	jmp	L1b2

L1a7:	w	sph,spl		; [sp] := r5:4
	ow	r5,r4

	db1f	r3,r3
	jzt	L1b1

	ll	0xff,r4

L1ac:	dw1	spl,spl		; [--sp] := 0xffff
	w	sph,spl
	ow	r4,r4

	db1	r3,r3
	jzbf	L1ac

L1b1:	dw1	spl,spl
L1b2:	w	sph,spl
	ow	r7,r6
	
	cl	0x0,r2
	jzbt	L1bb
	
L1b6:	dw1	spl,spl
	w	sph,spl
	ow	r3,r3
	
	db1	r2,r2
	jzbf	L1b6
	
L1bb:	mb	r8,r6
	jmp	L031


L1bd:	r	sph,spl
	iw	0x0,mpl
	slw	r6,gl
	orwf	mpl,gl
	rfs


; opcode 0xda: INN - set membership
op_inn:	mw	spl,r4
	aw	r2,spl
	r	sph,spl
	iw	0x0,r2
	jsr	L1d1
	aw	r2,r4
	cwf	spl,r4
	jcf	L1d0
	icb1	r6,r6
	r	r5,r4
	iw	0x0,r2
L1cd:	srwf	r3,r3
	db1	r6,r6
	jzbf	L1cd
L1d0:	slbc	r7,r6		; 1d0: translation 5d (row 59) - write one word to stack and end instruction


L1d1:	ll	0xf,r6
	nb	r2,r6
	srw	r3,r3
	srw	r3,r3
	srw	r3,r3
	srw	r3,r3		; 1d6: translation 6b (row 04)


L1d7:	ll	0x0,r7
	ll	0x1,r6
	srbf	r6,r6
	mb	r8,r8
	jzbt	L1df
L1dc:	slwc	r6,r6
	db1	r8,r8
	jzbf	L1dc
L1df:	rfs


; opcode 0xdb: UNI - set UNIon
op_uni:	jzt	L189
	mw	r2,r6
	lgl	r3
	aw	spl,r2
	riw1	r3,r2
	ibf	0x1,r8
	jzt	L1fb
	cb	r6,r8
	jc8f	L1f2

L1e9:	riw1	sph,spl
	iw	0x0,r4

	riw1	r3,r2
	iw	0x4,gl
	orw	r4,gl
	ow	gh,gl

	db1f	r6,r6
	jzf	L1e9
	jmp	op_nop
	
L1f2:	mb	r8,r7
L1f3:	riw1	r3,r2
	iw	0x0,r4

	riw1	sph,spl
	iw	0x4,gl
	orw	r4,gl
	ow	gh,gl

	db1f	r7,r7
	jzf	L1f3
L1fb:	mw	r6,r4
	sb	r8,r4
	aw	spl,r4
	icw1	r6,r6
	aw	r6,spl
	jmp	L16f


; opcode 0xdc: INT - set INTersection
op_int:	jzf	L206
	r	sph,spl
	iw	0x0,r4
	aw	r4,spl
	jmp	L107

L206:	jsr	L21c
	jzt	L22c
	cb	r7,r6
	jc8t	L210
	sb	r6,r7
	mb	r7,r8
	mb	r6,r7
	mb	r8,r6
	jsr	L213
	jmp	L185

L210:	sb	r7,r6
	jsr	L213
	aw	r6,spl		; 212: translation 3e (row 76) - end of instruction


L213:	riw1	sph,spl
	iw	0x0,r4

	riw1	r3,r2
	iw	0x4,gl
	nw	r4,gl
	ow	gh,gl
	db1	r7,r7
	jzbf	L213
	rfs


L21c:	mb	r2,r6
	lgl	r3
	aw	spl,r2
	riw1	r3,r2
	ibf	0x1,r7
	rfs


L222:	wiw1	sph,spl
	ow	mph,mpl
	ll	0x0,r8
	lgl	r8
	slw	r2,gl
	orwf	r4,gl
	rfs


; opcode 0xdd: DIF - set DIFference
op_dif:	jzt	op_nop
	jsr	L21c
	jzf	L22d
L22c:	dw1	r2,spl		; 22c: translation 3e (row 77) - end of instruction

L22d:	cb	r6,r7
	jc8f	L230
	mb	r6,r7
L230:	sb	r7,r6
L231:	riw1	sph,spl
	iw	0x0,r4

	riw1	r3,r2
	iw	0x4,gl
	ncw	r4,gl
	ow	gh,gl

	db1f	r7,r7
	jzf	L231
	aw	r6,spl		; 239: translation 3e (row 78) - end of instruction


; opcode 0xd4: FJP - False JumP (from translation 3b)
tt_77:	tl	0x1,r2
	jzbf	L296


; opcode 0x8a: UJP - Unconditional JumP (from translation 3d)
tt_30:
L23c:	ll	0xff,r3,lrr	; 23c: translation 1f subr (row 51)
	slbf	r6,r2
	cmb	r3,r7
L23f:	dw1	ipcl,r2
	icw2	r6,ipcl,lrr	; 240: translation 75 subr (row 81)
	srwcf	ipch,ipch
L242:	awc	r2,ipcl,lrr	; 242: translation 6e subr (row 15)
	jcf	op_nop
	dw1	ipcl,r8		; 244: translation 79 (row 84)


tt_10:	; from translation 79
tt_11:	; from translation 79
; opcode 0x9c: NOP - No OPeration
op_nop:	nop			; 245: translation 3e (row 79) - end of instruction


; opcode 0xd2: EFJ - Equal False Jump (from translation 37)
tt_75:	xwf	r2,r4
	jzf	L23c
	jmp	L296


; opcode 0xd3: NFJ - Not equal False Jump (from translation 37)
tt_76:	xwf	r2,r4
	jzt	L23c
	jmp	L296


; opcode 0x8b: UJPL - Unconditional JumP Long (from translation 3d)
tt_31:	nop	,lrr		; 24c: translation 76 subr (row 54)
	jmp	L250


; opcode 0xd5: FJPL - False JumP Long (from translation 3b)
tt_78:	srbf	r2,r2,lrr	; 24e: translation 76 subr (row 54)
	jct	op_nop
L250:	slbf	r7,r3
	jmp	L23f


; opcode 0xd6: XJP - case JumP (from translation 3b)
tt_79:	ll	0x4,r4
	lgl	r4,lrr		; 253: translation 7a subr (row 36)
	aw	gl,r6
	ll	0x0,r8
	jmp	L2e9


L257:	r	gh,gl
	iw	0x0,r2
	aw	gl,r2
	sb	r6,r2
	cdb	r3

	r	r3,r2
	iw	0x0,r2
	aw	gl,r2

	riw1	r3,r2
	iw	0x0,r6
	al	0x4,r6
	cib	r7
	swf	r6,spl

	ll	0x1,r8		; G := CTP
	lgl	r8

	icw2	gl,r6		; r9:8 := [CTP+2]  splow
	riw1	r7,r6
	iw	0x0,r8
	
	jct	L2c5
	cwf	r8,spl
	jct	L2c5
	slw	ipcl,ipcl,lrr	; 26c: translation 75 subr (row 82)

	ll	0xfd,r6		; r7:6 := 0xfffd (-3)
	ll	0xff,r7

	mw	r6,r8
	lgl	r4
	aw	gl,r6
	aw	mpl,r8
	mw	spl,mpl

	wiw1	mph,mpl
	ow	r7,r6

	wiw1	mph,mpl
	ow	r9,r8

	wiw1	mph,mpl
	ow	ipch,ipcl

	w	mph,mpl
	ob	r5,r5,rsvc
	mw	r2,ipcl


; opcode 0x97: CPF - Call Procedure Formal
op_cpf:	riw1	sph,spl
	iw	0x0,r8

	ll	0x0,r4
	lgl	r4

	riw1	sph,spl
	iw	0x0,gl

	al	0x3,gl
	cib	gh

	mbf	r9,r6

	jmp	L5fc


	nop	,lrr		; 287: translation 6e (row 16)


; opcode 0x90: CPL - Call Local Procedure
op_cpl:	ll	0x7,r4
	jmp	L28b


; opcode 0x91: CPG - Call Global Procedure
op_cpg:	ll	0x5,r4
L28b:	jsr	L0c6
	ll	0x4,r8
	lgl	r8
	sw	gl,ipcl
	ll	0x0,r5
	jmp	L257


; opcode 0x93: CXL - Call eXternal procedure Local
op_cxl:	ll	0x7,r4
	jsr	L0c6
	jmp	L29c


; opcode 0x94: CXG - Call eXternal procedure Global
op_cxg:	ll	0x5,r4,lrr	; 294: translation 1f subr (row 52)
	jmp	L29c


L296:	nop	,lrr		; 296: translation 1f subr (row 52)
	nop	,rsvc


L298:	lgl	r6

	mw	r4,gl
	ll	0x0,r4
	mw	r2,r6

L29c:	jsr	L2ba
	jsr	L2a6
	jsr	L0c6
L29f:	sw	gl,ipcl
	mw	r2,gl
	jmp	L257

L2a2:	lgl	r6
	mw	r4,gl
	ll	0x0,r4
	jmp	L28b

L2a6:	r	r7,r6
	iw	0x4,r6
	icw1	r6,r6
	ow	r7,r6

L2aa:	r	gh,gl
	iw	0x0,r6
	aw	gl,r6
	r	r7,r6
	ib	0x1,r5		; 2ae: translation 6b (row 05)


L2af:	ll	0x2,r2
	lgl	r2
	aw	gl,r6
L2b2:	ll	0x4,r2
	lgl	r2
	r	r7,r6
	iw	0x0,r6
	riw2	r7,r6
	iw	0x0,r2		; 2b7: translation 6b (row 06)


L2b8:	mbf	r5,r6
L2b9:	ll	0x0,r7

L2ba:	jnf	L2af
	nl	0x7f,r6
	ll	0x1,r2
	lgl	r2
	mw	gl,r2
	al	0xb,r2
	cib	r3
	r	r3,r2
	iw	0x0,r2
	aw	r2,r6
	jmp	L2b2


L2c5:	jmp	L590


; opcode 0x96: RPU - Return from Procedure User
op_rpu:	dw1	mpl,mpl		; sp := mp (adjusted)
	dw1	mpl,spl

	riw1	sph,spl		; mp := lm^.m.msdyn1
	iw	0x0,mpl
	al	0x3,mpl
	cib	mph

	ll	0x4,r8		; g = segb
	lgl	r8,lrr		; 2cd: translation 7a subr (row 33)

	riw1	sph,spl
	iw	0x0,ipcl

	riw1	sph,spl
	ibf	0x1,r5
	aw	r6,spl
	jzt	L2dc

	jsr	L2b8
	jsr	L2aa
	mw	r2,gl
	jsr	L2b8

	r	r7,r6
	iw	0x4,r6
	dw1	r6,r6
	ow	r7,r6

L2dc:	mw	gl,r2
	srwf	ipch,ipch
	jmp	L242


	nop			; 2df: translation 3d (row 18)


; opcode 0x9e: BPT - Break PoinT
op_bpt:	ll	0xe,r6		; raise exception 14 - halt or breakpoint
	jmp	raise_exception


; opcode 0xc6: DUP2 - DUPlicate 2 words of stack (from translation 37)
tt_63:	al	0xfd,spl
	cdb	sph
	mw	r2,r6
	mw	r4,r2


; opcode 0xbd: SWAP - SWAP top of stack with next of stack
op_swap:
	w	sph,spl
	ow	r3,r2
	dw1	spl,spl		; 2e8: translation 5d (row 60) - write one word to stack and end instruction


L2e9:	riw1	r7,r6
	iw	0x0,r4
	swf	r4,r2
	jnt	op_nop
	lgl	r8
	riw1	r7,r6
	iw	0x0,gl
	sw	r4,gl
	cwf	r2,gl
	jct	op_nop
	aw	r2,r6
	r	r7,r6
	iw	0x0,r6
	jmp	L250


	nop
	nop
	nop			; 2f9: translation 6e (row 17) ?
	nop			; 2fa: translation 5e (row 85) ?


; from translation 75, TSR = X1, loads TSR := 2
tt_12:	al	0xff,ipcl
	cdb	ipch		; 2fc: translation 6b (row 13)



tt_08:	; from translation 5e, unconditional, loads TSR := 1
tt_09:	; from translation 6e, unconditional, loads TSR := 2
tt_13:	; from translation 75, TSR = X0, loads TSR := 2
	nop
	nop			; 2fe: translation 6b (row 13)


; opcode 0xc1: SBR - SuBtract Real (from translation 2f)
tt_58:	al	0x80,r3

; opcode 0xc0: ADR - ADd Real (from translation 2f)
tt_57:	jmp	L32f


; opcode 0xc3: DVR - DiVide Real (from translation 37)
tt_60:	jmp	L39a


; opcode 0xc2: MPR - MultiPly Real (from translation 2f)
tt_59:	jmp	L37d


; opcode 0xcc: FLT - FLoaT top of stack (from translation 3b)
tt_69:	mwf	r2,r6
	jzt	L313
	ll	0x8e,r3
	ll	0x0,r8
	jnf	L30b
	ll	0x80,r8
	tcwf	r6,r6
	jnt	L30e
L30b:	slwf	r6,r6
	db1	r3,r3
	jnf	L30b
L30e:	slb	r7,r2
	mb	r6,r7
	ll	0x0,r6
	srw	r3,r3
	orb	r8,r3
L313:	dw1	spl,spl
	jmp	L3f6


; opcode 0xbe: TNC - TruNCate real
op_tnc:
; opcode 0xbf: RND - RouND real
op_rnd:
	slwf	r2,r2
	jzt	L32e
	mb	r7,r6
	srb	r2,r7
	al	0x80,r7
	al	0x82,r3
	jnbf	L31d
	jmp	L4bd

L31d:	cl	0x10,r3
	jc8t	floating_point_error
	al	0xf1,r3
	jzbt	L324
L321:	srw	r7,r7
	icb1	r3,r3
	jzbf	L321
L324:	tl	0x1,r4
	jzbt	L32b
	srw	r7,r7
	jc8f	L32c
	icw1	r6,r6
	jnbf	L32c
	jmp	floating_point_error

L32b:	srw	r7,r7
L32c:	jcf	L32e
	tcw	r6,r6
L32e:	jmp	L164


L32f:	jsr	L222
	jzf	L332
	jmp	L163

L332:	jsr	L1bd
	jzf	L336
	mw	r4,r6
	jmp	L3f3

L336:	jsr	L4c5
	cb	r8,gl
	jzbf	L348
	cbf	r3,r7
	jsr	L35e
	awf	r4,r6
	abcf	r2,gh
	jcf	L343
	srbcf	gh,gh
	srwcf	r7,r7
	srbcf	gl,gl
	srwc	mph,mph
	icb1	r3,r3
L343:	r	sph,spl
	ib	0x1,r2
	tl	0xfe,r8
	jzbt	L3dd
	jmp	L3eb

L348:	cwf	r2,r6
	jzf	L34c
	cwf	r4,mpl
	jzt	L3fa
L34c:	jsr	L35e
	tcwf	mpl,mpl
	sbcf	gl,r8
	swcf	r4,r6
	sbc	gh,r2
	mbf	r2,gh
	mb	r8,gl
	ll	0x0,r8
	jnt	L343
L355:	slwf	mpl,mpl
	slbcf	gl,gl
	slwcf	r6,r6
	slbcf	gh,gh
	icb1	r8,r8
	jnf	L355
	sb	r8,r3
	jc8t	L343
	jmp	L3fa


L35e:	jcf	L365
	mb	r3,r8
	sbf	r7,r8
	mb	r6,gh
	mw	r4,r6
	mw	mpl,r4
	jmp	L36b

L365:	mb	r8,gl
	mb	r7,r8
	sbf	r3,r8
	mb	r2,gh
	mw	r6,r2
	mw	mpl,r6
L36b:	cl	0x19,r8
	jc8f	L370
	nl	0x7f,r2
	orb	gl,r2
	jmp	L3f1

L370:	w	sph,spl
	ob	gl,gl
	ll	0x0,gl
	ll	0x0,mph
	ll	0x0,mpl
	jzt	L37c
L376:	srbf	gh,gh
	srwcf	r5,r5
	srbcf	gl,gl
	srwc	mph,mph
	db1	r8,r8
	jzbf	L376
L37c:	rfs


L37d:	jsr	L222
	jzt	L3fa
	jsr	L1bd
	jzt	L3fa
	jsr	L4c5
	ll	0x0,gh
	ab	r7,r3
	cib	gh
	al	0x81,r3
	cdb	gh
	mb	gh,r7
	jnbt	L3fa
	jzbf	L3fd
	xb	gl,r8
	mb	r6,gl
	slbf	r8,r6
	ll	0x18,r8
	srbcf	gl,gl
	srwcf	mph,mph
L390:	jcf	L393
	awf	r4,r6
	abcf	r2,gh
L393:	srbcf	gh,gh
	srwcf	r7,r7
	srbcf	gl,gl
	srwcf	mph,mph
	db1	r8,r8
	jzbf	L390
	jmp	L3d4


L39a:	jsr	L222
	jzt	floating_point_error
	jsr	L1bd
	jzt	L3fa
	jsr	L4c5
	xb	gl,r8
	slbf	r8,gh
	sb	r3,r7
	cdb	gh
	mb	r7,r3
	al	0x7e,r3
	cib	gh
	mb	gh,r7
	jnbt	L3fa
	jzbf	L3fd
	mb	r6,gl
	slbc	r7,r6
	ll	0x1b,r8
	w	sph,spl
	ow	ipch,ipcl
	srw	r7,ipch
	jmp	L3bd


L3b0:	slwf	r6,r6
	slwc	ipcl,ipcl
	slwf	mpl,mpl
	slwc	gl,gl
	jzbf	L3b6
	jzt	L3c3
L3b6:	tl	0x2,gh
	jzbt	L3bc
	awf	r4,mpl
	abc	r2,gl
	cib	gh
	jmp	L3c0

L3bc:	al	0x1,r6
L3bd:	swf	r4,mpl
	sbc	r2,gl
	cdb	gh
L3c0:	db1	r8,r8
	jzbf	L3b0
	jmp	L3c9

L3c3:	al	0x1,r6
	jmp	L3c7

L3c5:	slwf	r6,r6
	slwc	ipcl,ipcl
L3c7:	db1	r8,r8
	jzbf	L3c5
L3c9:	orb	gl,mpl
	srwf	ipch,ipch
	srwcf	r7,r7
	srbc	gl,gl
	srwf	ipch,ipch
	srwcf	r7,r7
	srbc	gl,gl
	srbf	ipch,ipch
	mb	ipcl,gh
	r	sph,spl
	iw	0x0,ipcl
L3d4:	srbc	r8,r2
	tl	0x80,gh
	jzbf	L3db
	slbf	gl,gl
	slwcf	r6,r6
	slbc	gh,gh
	jmp	L3dd

L3db:	icb1	r3,r3
	jc8t	L3fd
L3dd:	al	0x80,gl
	jc8f	L3eb
	icw1f	r6,r6
	jcf	L3e2
	icb1f	gh,gh
L3e2:	orb	mph,mpl
	orb	mpl,gl
	jzbf	L3e6
	nl	0xfe,r6
L3e6:	jcf	L3eb
	srbf	gh,gh
	srwc	r7,r7
	icb1	r3,r3
	jc8t	L3fd
L3eb:	cl	0xff,r3
	jzbt	L3fd
	cl	0x0,r3
	jzbt	L3fa
	nl	0x7f,gh
	orb	gh,r2
L3f1:	slbf	r2,r2
	srwc	r3,r3
L3f3:	dw1	spl,spl
	riw1	sph,spl
	iw	0x0,mpl
L3f6:	w	sph,spl
	ow	r7,r6
	dw1	spl,spl
	jmp	L107

L3fa:	xw	r2,r2
	xw	r6,r6
	jmp	L3f3

L3fd:	dw1	spl,spl
	jsr	L4b4

floating_point_error:
	ll	0xc,r6		; raise exception 12 - floating point error
	jmp	raise_exception


; dispatch opcodes 0x90..0x9f (from translation 3d)
tt_36:	ll	0x0,r7
	nl	0xf,r6
	mi	r7,r6
	jmp	L410


; dispatch opcodes 0xb8..0xbf (from translation 3b)
tt_55:	mb	r6,r4
	r	sph,spl
	iw	0x0,r6
	ll	0x0,r5
	nl	0x7,r4
	mi	r5,r4
	jmp	L420


; dispatch opcodes 0xd8..0xdf (from translation 3b)
tt_81:	ll	0x0,r7
	nl	0x7,r6
	mi	r7,r6
	jmp	L428


; jump table for opcodes 0x90..0x9f
L410:	jmp	op_cpl		; 0x90 CPL  - Call Procedure Local
	jmp	op_cpg		; 0x91 CPG  - Call Procedure Global
	jmp	op_cpi		; 0x92 CPI  - Call Procedure Intermediate
	jmp	op_cxl		; 0x93 CXL  - Call eXternal procedure Local
	jmp	op_cxg		; 0x94 CXG  - Call eXternal procedure Global
	jmp	op_cxi		; 0x95 CXI  - Call eXternal procedure Intermediate
	jmp	op_rpu		; 0x96 RPU  - Return From Procedure User
	jmp	op_cpf		; 0x97 CPF  - Call Procedure Formal
	jmp	op_ldcn		; 0x98 LDCN - LoaD Constant Nil
	jmp	op_lsl		; 0x99 LSL  - Load Static Link
	jmp	op_lde		; 0x9a LDE  - LoaD word Extended
	jmp	op_lae		; 0x9b LAE  - Load Address Extended
	jmp	op_nop		; 0x9c NOP  - No OPeration
	jmp	op_lpr		; 0x9d LPR  - Load Processor Register
	jmp	op_bpt		; 0x9e BPT  - Break PoinT
	jmp	op_bnot		; 0x9f BNOT - Boolean NOT (was RBP in early releases)


; jump table for opcodes 0xb8..0xbf
L420:	jmp	op_geqpwr	; 0xb8: GEQPWR - set compare >= (supserset of)
	jmp	op_equbyt	; 0xb9: EQUBYT - equal byte array compare
	jmp	op_leqbyt	; 0xba: LEQBYT - less or equal byte array compare
	jmp	op_geqbyt	; 0xbb: GEQBYT: greater or equal byte array compare
	jmp	op_srs		; 0xbc: SRS  - build SubRange Set
	jmp	op_swap		; 0xbd: SWAP - SWAP top of stack with next of stack
	jmp	op_tnc		; 0xbe: TNC - TruNCate real
	jmp	op_rnd		; 0xbf: RND - RouND real


; jump table for opcodes 0xd8..0xdf
L428:	jmp	op_ixp		; 0xd8 IXP - IndeX Packed array
	jmp	op_ste		; 0xd9 STE - STore word Extended
	jmp	op_inn		; 0xda INN - set membership
	jmp	op_uni		; 0xdb UNI - set UNIon
	jmp	op_int		; 0xdc INT - set INTersection
	jmp	op_dif		; 0xdd DIF - set DIFference
	jmp	op_signal	; 0xde SIGNAL - SIGNAL semaphore
	jmp	op_wait		; 0xdf WAIT - WAIT on semaphore


; opcode 0xb0: EQUI - EQUal Integer (from translation 37)
tt_46:	swf	r2,r6
L431:	jzt	L4c3
	jmp	L4bd


; opcode 0xb1: NEQI - Not EQual Integer (from translation 37)
tt_47:	swf	r2,r6
	jzf	L4c3
	jmp	L4bd


; opcode 0xb2: LEQI - Less than or EQual Integer (from translation 37)
tt_48:	cwf	r6,r2
	jvf	L447
	jmp	L446


; opcode 0xb3: GEQI - Greater than or EQual Integer (from translation 37)
tt_49:	cwf	r2,r6
	jvf	L447
	jmp	L449


; opcode 0xcd: EQUREAL - EQUal REAL (from translation 37)
tt_70:	jsr	L44c
	jmp	L4bd


	nop


; opcode 0xce: LEQREAL - Less than or EQual REAL (from translation 37)
tt_71:	jsr	L44c
	jnbt	L446
	jct	L446
	jmp	L449


; opcode 0xcf: GEQREAL - Greater than or EQual REAL (from translation 37)
tt_72:	jsr	L44c
	jnbt	L449
	jct	L449
L446:	mbf	r3,r3
L447:	jnf	L4c3
	jmp	L4bd

L449:	mbf	r3,r3
	jnt	L4c3
	jmp	L4bd

L44c:	riw1	sph,spl
	iw	0x0,r6
	mb	r7,r8
	cwf	r2,r6
	jzf	L455
	r	sph,spl
	iw	0x0,r6
	cwf	r4,r6
	jzt	L4c3
L455:	xb	r3,r8
	rfs


; opcode 0xb4: LEUSW - Less than or Equal UnSigned Word (from translation 37)
tt_50:	cwf	r6,r2
	jcf	L4c3
	jmp	L4bd


; opcode 0xb5: GEUSW - Greater than or Equal UnSigned Word (from translation 37)
tt_51:	cwf	r2,r6
	jcf	L4c3
	jmp	L4bd


; opcode 0xb6: EQUPWR - set compare EQUal (from translation 3b)
tt_52:	jsr	L473
	cw	r4,gl
	jzbf	L4b6
	jzf	L484
	cb	r7,r6
	jzbt	L4c2
	jc8t	L490
	jmp	L46c


; opcode 0xb7: LEQPWR - set compare Less than or EQual (from translation 3b)
tt_53:	jsr	L473
	orw	r4,gl
	cw	gl,r4
	jc8f	L4b6
	jzf	L484
	cb	r7,r6
	jc8t	L4c2
L46c:	sb	r6,r7
L46d:	riw1	sph,spl
	iwf	0x0,gl
	db1	r7,r7
	jzf	L4b9
	jzbf	L46d
	jmp	L4c2


L473:	mwf	r2,r6
	mw	spl,r2
	aw	r6,spl
	riw1	sph,spl
	ib	0x1,r7
	jzbf	L47b
	ll	0x1,r7
	dw1	spl,spl
L47b:	jzf	L47e
	ll	0x1,r6
	dw1	r2,r2
L47e:	mb	r7,r8
	cb	r7,r6
	jc8t	L482
	mb	r6,r8
L482:	ll	0x0,r4
	lgl	r4
L484:	riw1	r3,r2
	iw	0x0,r4
	riw1	sph,spl
	iw	0x0,gl
	db1f	r8,r8		; 488: translation 6b (row 07)


; opcode 0xb8: GEQPWR - set compare >= (supserset of)
op_geqpwr:
	jsr	L473
	orw	gl,r4
	cw	r4,gl
	jc8f	L4b6
	jzf	L484
	cb	r6,r7
	jc8t	L4bf
L490:	sb	r7,r6
L491:	riw1	r3,r2
	iwf	0x0,r4
	jzf	L4bc
	db1f	r6,r6
	jzf	L491
	jmp	L4c2


; opcode 0xb9: EQUBYT - equal byte array compare
op_equbyt:
	mw	r6,r4,lrr	; 497: translation 7a subr (row 38)
	jsr	L4a4
	jmp	L431


; opcode 0xba: LEQBYT - less or equal byte array compare
op_leqbyt:
	mw	r6,r4,lrr	; 49a: translation 7a subr (row 34)
	jsr	L4a4
	jcf	L4c3
	jmp	L4bd


	nop


; opcode 0xbb: GEQBYT: greater or equal byte array compare
op_geqbyt:
	mw	r6,r4,lrr	; 49f: translation 7a subr (row 38)
	jsr	L4a4
	jzt	L4c3
	jct	L4c3
	jmp	L4bd


L4a4:	w	sph,spl
	ow	mph,mpl
	ll	0x0,r8
	lgl	r8
L4a8:	riw1	r3,r2
	iw	0x0,mpl
	riw1	r5,r4
	iw	0x0,gl
	cbf	gl,mpl
	jzf	L4b4
	dw1	r6,r6
	jzbt	L4b4
	cbf	gh,mph
	jzf	L4b4
	dw1	r6,r6
	jzbf	L4a8
L4b4:	r	sph,spl
	iw	0x0,mpl		; 4b5: translation 6b (row 08)


L4b6:	cb	r7,r6
	jc8t	L4ba
	sb	r6,r7
L4b9:	ab	r7,r8
L4ba:	ab	r8,spl
	cib	sph
L4bc:	dw1	spl,spl
L4bd:	ll	0x0,r6
	ll	0x0,r7		; 4be: translation 5d (row 61) - write one word to stack and end instruction


L4bf:	sb	r6,r7
	ab	r7,spl
	cib	sph
L4c2:	dw1	spl,spl
L4c3:	ll	0x1,r6
	ll	0x0,r7		; 4c4: translation 5d (row 62) - write one word to stack and end instruction


L4c5:	ll	0x1,r8
	ll	0x1,gl
	slwf	r6,r6
	srbcf	r8,r8
	srbc	r6,r6
	slwf	r2,r2
	srbcf	gl,gl
	srbc	r2,r2
	rfs


L4ce:	mw	r6,mpl
	jzt	L4d1
	mb	r4,r5

L4d1:	r	mph,mpl
	ibf	0x1,r4

	dw1	mpl,ipcl
	dw1	ipcl,ipcl

	r	ipch,ipcl
	iw	0x0,r6

	al	0x3,r6
	cib	r7
	cw	r6,r2
	jc8f	L4dd
	cw	r6,r8
	jc8f	L4ce

L4dd:	dw1	ipcl,spl
	jsr	L2b8
	mw	r2,gl
	jmp	L55b		; 4e0: translation 5d (row 63) - OVERRIDDEN BY JMP


; opcode 0xd1: SPR - Store Processor Register (from translation 37)
tt_74:	icb1f	r4,r8
	jnf	L4e6

	tcb	r4,r4		; r4 := -r4
	lgl	r4,rsvc		; g := r4 & 7
	mw	r2,gl		; [rg] := r2

; SPR positive register
L4e6:	mw	r2,r6
	jsr	updatetib
	jsr	L5af
	lgl	r2
	jzf	L4ec
	jmp	L5d5


L4ec:	aw	gl,r4
	w	r5,r4
	ow	r7,r6
	jmp	L5d6


; opcode 0x9d: LPR - Load Processor Register
op_lpr:	r	sph,spl		; r5:4 = [sp]
	iwf	0x0,r4

	jnf	L4f7		; jump if positive

; LPR negative register
	tcb	r4,r4		; r4 := -r4
	lgl	r4		; g := r4 & 7
	w	sph,spl,rsvc	; [sp] := [rg]
	ow	gh,gl


; LPR positive register
L4f7:	jsr	updatetib
	jsr	L5af

	lgl	r2		; r5:4 := r5:4 + ctp
	aw	gl,r4

	r	r5,r4		; [sp] := [r5:4]
	iw	0x0,r6
	w	sph,spl
	ow	r7,r6

	jmp	L5d6


; interrupt 3 (highest priority), from end of instruction (translation 3e)
tt_03:	ll	0x8,r2
	jmp	L507

; interrupt 2, from end of instruction (translation 3e)
tt_02:	ll	0x4,r2
	jmp	L507

; interrupt 1, from end of instruction (translation 3e)
tt_01:	ll	0x2,r2
	jmp	L507

; interrupt 0 (lowest priority), from end of instruction (translation 3e)
tt_00:	ll	0x1,r2		; r2 := 1

L507:	ll	0xfc,r5		; r5:4 := 0xfc40
	ll	0x40,r4
	w	r5,r4		; [0xfc40] := interrupt bit to clear
	ob	r2,r2		; clear the bit which was set in r2

	ll	0x60,r4		; r5:4 := 0xfc60

	ra	r5,r4		; r7:6 := [0xfc60] ; read interrupt vector
	iw	0x0,r6

	r	r7,r6		; r3:2 := [r7:6]
	iw	0x0,r2

; opcode 0xde: SIGNAL - SIGNAL semaphore
op_signal:
	riw1	r3,r2		; r5:4 := [r3:2++]
	iwf	0x0,r4

	jzt	L51c

L513:	icw1	r4,r4
	dw1	r2,r2
	w	r3,r2
	ow	r5,r4

	ll	0x1,r2
	lgl	r2
	cl	0xfc,gh
	jzbt	L587
L51b:	jmp	op_nop

L51c:	r	r3,r2
	iw	0x0,r6
	cl	0xfc,r7
	jzbt	L513
	r	r7,r6
	iw	0x0,r4
	w	r3,r2
	ow	r5,r4
	jsr	L560
	mw	r4,gl
	ll	0x1,r2
	lgl	r2
	cl	0xfc,gh
	jzbt	L587
	icw1	gl,r2
	r	r3,r2
	iw	0x0,r2
	icw1	r6,r6
	r	r7,r6
	iw	0x0,r6
	cwf	r2,r6
	jct	L51b
	mw	gl,r6
	jsr	L563
	mw	r4,gl
	jsr	updatetib
	jsr	L5af
	jmp	L587


; opcode 0xdf: WAIT - WAIT on semaphore
op_wait:
	riw1	r3,r2		; r5:4 := [r3:2]
	iwf	0x0,r4
	jzt	L53f
	dw1	r4,r4		; r5:4 -= 1
	dw1	r2,r2		; r3:2 -= 1
	w	r3,r2,rsvc	; [r3:2] := r5:4
	ow	r5,r4

L53f:	r	r3,r2		; r5:4 := [r3:2]
	iw	0x0,r4

	ll	0x1,r8	;	 r7:6 := CTP
	lgl	r8
	mw	gl,r6

	dw1	spl,spl		; sp--
	jsr	L563

	riw1	sph,spl		; r7:6 := [sp++]
	iw	0x0,r6

	icw1	r6,r2		; r7:6 += 1

	w	r3,r2		; [r3:2] := r5:4
	ow	r5,r4

	jsr	updatetib
	jsr	L5af
	w	r9,r8
	ow	r7,r6
	jmp	L587


; opcode 0x9f: BNOT - Boolean NOT (was RBP in early releases)
op_bnot:
	r	sph,spl		; r6 := [sp], lower byte, RMW
	ib	0x5,r6

	ocb	r6,r6		; r6 ^= 0xff
	nl	0x1,r6,rsvc	; r6 &= 0x01
	ob	r6,r6		; [sp] := r6
				; instruction done


L555:	mbf	r5,r5
	jzf	L55a

	ll	0x4,r6		; g = segb
	lgl	r6
	jsr	L2aa
L55a:	jmp	L4d1


L55b:	r	gh,gl
	iw	0x0,ipcl
	aw	gl,ipcl

	ll	0x4,r6		; raise exception 4 - stack overflow
	jmp	raise_exception


L560:	ll	0x3,r2		; g := RQ
	lgl	r2
	mw	gl,r4


L563:	dw1	spl,spl		; [--sp] := mp
	w	sph,spl
	ow	mph,mpl

	dw1	spl,spl		; [--sp] := r5:4
	w	sph,spl
	ow	r5,r4

	ll	0xfc,r3		; r3:2 := 0xfc00 (Nil)
	ll	0x0,r2
	lgl	r2
	icw1	r6,gl
	r	gh,gl
	iw	0x0,gl
	jmp	L573


L570:	mw	r4,r2
	r	r5,r4
	iw	0x0,r4

L573:	cl	0xfc,r5		; is r5:r4 NIL?
	jzbt	L57a

	icw1	r4,mpl
	r	mph,mpl
	iw	0x0,mpl
	cwf	gl,mpl
	jcf	L570

L57a:	w	r7,r6
	ow	r5,r4

	cl	0xfc,r3		; is r3:r2 NIL?
	jzbf	L57f

	mw	spl,r2
L57f:	w	r3,r2
	ow	r7,r6

	riw1	sph,spl
	iw	0x0,r4

	riw1	sph,spl
	iw	0x0,mpl

	ll	0x3,r2		; g := rq
	lgl	r2		; 586: translation 6b (row 09)


L587:	ll	0x3,r9		; g := rq
	lgl	r9

	mw	gl,r6		; r7:6 := rq

	cl	0xfc,gh		; is rq nil?
	jzbt	L58e

	mw	gl,r2
	jmp	L5d1


; no task on ready queue, wait for interrupt
; from translation 6d
; sits in a loop constantly doing translation 6d, until an interrupt occurs
; (when interrupt reg = 0XX0000)
tt_07:
L58e:	lgl	r2		; rq := r7:6	; 58e: translation 6d (row 86)
	mw	r6,gl		; 58f: translation 3e (row 80) - end of instruction


L590:	r	r7,r6		; r3:2 := [r7:6]
	iw	0x0,r2
	jmp	L555


	nop
	nop
	nop
	nop
	nop


; 0x598
updatetib:
	ll	0x1,r2		; ctp^.t.sp := sp
	lgl	r2
	icw2	gl,r8
	icw2	r8,r8
	wiw1	r9,r8
	ow	sph,spl

	al	0xfd,mpl	; ctp^.t.mp := mp
	cdb	mph
	wiw1	r9,r8
	ow	mph,mpl
	
	ll	0x5,r3		; ctp^.t.bp := bp (adjusted)
	lgl	r3
	al	0xfd,gl
	cdb	gh
	wiw2	r9,r8
	ow	gh,gl

	ll	0x4,r3		; ctp^.t.segb := segb
	lgl	r3
	w	r9,r8
	ow	gh,gl
	
	dw1	r8,r8		; ctp^.t.ipc := ipc (adjusted)
	sw	gl,ipcl
	slw	ipcl,ipcl	; 2ae: translation 75 (row 83)


L5af:	wiw2	r9,r8
	ow	ipch,ipcl	; 5b0: translation 6b (row 10)


; boostrap code
; see Figure 7-8 "Bootstrap Microcode/Software Instruction",
; Western Digital UCSD Pascal III.0 Operating System Reference Manual,
; Release A0, July 1982
reset:	ll	0xfc,r5		; R4:5 := fc68, addr of boot config reg
	ll	0x68,r4

	r	r5,r4		; read boot config reg into R3:2
	iwf	0x0,r2
	jzf	L5c8		; if non-zero, go boot from ROM

; boot config reg is zero, so load track 1 from floppy into RAM starting at 0

	ll	0x30,r4		; R4:5 := fc30 - FDC

	ll	0x1,r7		; write 010f to FDC (unit # restore unit)
	ll	0xf,r6
	jsr	L5ec

	ll	0x5f,r6		; write 015f to FDC (unit #, step in)
	jsr	L5ec

	ll	0x38,r8		; write 0x0031 to FC38 (DMAC control)
	ll	0x31,r6
	w	r5,r8
	ob	r6,r6

	ll	0x94,r6		; write 0x0194 to FC30 (FDC command)
	w	r5,r4
	ow	0x7,r6

	ll	0x18,r4		; r4:5 := fc18

L5c4:	r	r5,r4		; r8 := FDC status reg
	ib	0x1,r8
	tl	0x30,r8
	jzbt	L5c4

; boot from ROM or code loaded from floppy track 1
; R3:2 points to CTP (points to TIB), SDP, RQP
L5c8:	ri	i6		; reset interrupts

	riw1	r3,r2		; r7:6 := [r3:2++]
	iw	0x0,r6		;   will later copy into CTP

	ll	0x2,r8		; G := 2(SSV)
	lgl	r8
	riw1	r3,r2		; SSV := [r3:2++]
	iw	0x0,gl

	ll	0x3,r8		; G := 3 (RQ)
	lgl	r8

L5d1:	r	r3,r2		; RQ := [r3:2]
	iw	0x0,gl		; input word to R1:R0

	ll	0x1,r8		; G := 1 (CTP)
	lgl	r8

L5d5:	mw	r6,gl		; CTP := r7:6 

L5d6:	icw2	rgl,r2		; r3:2 := CTP + 4
	icw2	r2,r2

	riw1	r3,r2		; SP rd:c := [r3:2++]
	iw	0x0,spl

	riw1	r3,r2		; MP rf:e := [r3:2++] + 3
	iw	0x0,mpl
	al	0x3,mpl
	cib	mph

	ll	0x5,r4		; G := 5 (BP)
	lgl	r4
	riw1	r3,r2		; BP := [r3:2++]
	iw	0x0,gl

	al	0x3,gl
	cib	r1

	riw1	r3,r2		; ipc := [r3:2++]
	iw	0x0,ipcl

	ll	0x4,r4		; G := 4 (SEGB)
	lgl	r4
	r	r3,r2		; segb = [r3:42]
	iw	0x0,gl

	jmp	L2dc


	nop


; issue an FDC command and wait for completion
L5ec:	w	r5,r4		; write to FDC cmd reg (addr in r5:4)
	ow	r7,r6		;   from value in r7:6

L5ee:	icb2	r2,r2		; delay quite a bit
	jzbf	L5ee

L5f0:	r	r5,r4		; read FDC status reg
	ib	0x1,r8		;   into R8

	tl	0x1,r8		; is busy bit set?
	jzbf	L5f0		;   yes, loop
	rfs			;   no, done


unimplemented_instruction:
	ll	0xb,r6		; raise exception 11 - unimplemented instruction

; raise exception, number in r6
; page C-36
raise_exception:
	dw1	spl,spl		; [--sp] := r6
	w	sph,spl
	ob	r6,r6

	ll	0x5,r4		; CXG 2,2
	ll	0x2,r8
	mbf	r8,r6

L5fc:	jsr	L2b9
	jsr	L2a6
	mb	r8,r6
	jmp	L29f


; optional fourth MICROM for extended instructions
; If an extended instruction jumps here, and there is no MICROM present,
; the MIB will contain a jmp 000 instruction, and at 000 there is a
; jmp unimplemented_instruction.
L600:
