; Pascal Microengine microcode, MICROMs CP2171-14, CP2171-15, CP2171-18
; Reverse-engineered source code
; Copyright 2015, 2016 Eric Smith <spacewar@gmail.com>

; Reverse-engineering in progress:
;   There are probably many errors.
;   There is no existing assembler that can assemble this file as-is.

; Note that there are jumps and subroutine returns that occur on
; microinstructions that aren't explicit flow control instructions, due
; to the translation PLAs in the control chip. At present, only the OR planes
; of these PLAs have been transcribed.  The origin addresses of the
; translations (matched by array 1, the AND plane of the first PLA) have not
; yet been transcribed, but the branch targets of the translations (ouputs
; of array 4, the OR plane of the second PLA) are designated here by labels
; of the form tt_nn, where nn is row number of array 4.  There are no labels
; tt_14, tt_98, and tt_99, because rows 98 and 99 are unused, and row 14
; causes a subroutine return rather than a jump to a fixed address.

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

	jmp	unimplemented_instruction	; addr 0x000


  	jmp	reset		; cold start (addr 0x001)


tt_95:	riw1	ipch,ipcl	; r9:8, tr := [ipc++]; load ics
	iw	0x3,r8

	mbf	r8,r6

	ll	0x0,r7
tt_96:	mbf	r9,r6

L007:	ll	0x0,r7

tt_93:	riw1	ipch,ipcl	; r9:8, tr := [ipc++]; load ics
	iw	0x3,r8

	mbf	r8,r6		; r6 := r8, update flags
	jnf	L007		; if 0x00..0x7f, go to L007

	nl	0x7f,r8		; mask off MSB
	mb	r8,r7
	mb	r9,r6
tt_94:	mbf	r9,r6
	jnf	L007

	nl	0x7f,r9
	mb	r9,r7

	riw1	ipch,ipcl	; r9:8, tr := [ipc++]; load ics
	iw	0x3,r8

	mb	r8,r6
	rtsr			; reset translation state

tt_04:	riw1	ipch,ipcl	; r9:8, tr := [ipc++]; load ics
	iw	0x3,r8

	mb	r8,r6,,1
	jmp	L600


tt_06:	r	r9,r8		; r9:8, tr := [r9:8]; load ics
	iw	0x3,r8
tt_05:	mb	r9,r6,,1
	jmp	L600


tt_91:	riw1	ipch,ipcl	; r7:6 := [ipc++]
	iw	0x0,r6

tt_92:	mb	r9,r6

	riw1	ipch,ipcl	; r9:8, tr := [ipc++]; load ics
	iw	0x3,r8

	mb	r8,r7

tt_56:	riw1	sph,spl		; r3:2 := [sp++]
	iwf	0x0,r2

	riw1	sph,spl		; r5:4 := [sp++]
	iwf	0x0,r4

	r	sph,spl		; r7:6 := [sp]
	iwf	0x0,r6
	
tt_37:
tt_54:	riw1	sph,spl		; r3:2 := [sp++]
	iwf	0x0,r2

tt_82:	r	sph,spl		; r7:6 := [sp]
	iwf	0x0,r6

	nop


L030:	nop


tt_16:
L031:	dw1	spl,spl
	w	sph,spl,rsvc
	ob	r6,r6

	
tt_20:	dw1	spl,spl,lrr
	w	sph,spl,rsvc
	ow	r7,r6

	
tt_21:	dw1	spl,spl,lrr
	w	sph,spl,rsvc
	ow	r7,r6


; opcode 0x98 LDCN - LoaD Constant Nil
L03a:	ll	0xfc,r7		; r7:6 := 0xfc00 (Nil)
	ll	0x0,r6

	dw1	spl,spl
tt_17:	ll	0x0,r7
	al	0xe1,r6

	aw	mpl,r6
tt_27:	nop	,lrr
	aw	mpl,r6
tt_18:	ll	0x0,r7
	al	0xd1,r6
	ll	0x5,r4
	lgl	r4
	aw	gl,r6
tt_25:	ll	0x5,r4
	lgl	r4,lrr
	aw	gl,r6
tt_29:	mw	mpl,r4,lrr
	jzf	L0d3,lrr
	jsr	L030
	aw	r4,r6

; opcode 0x9a LDE - LoaD word Extended
L04e:	jsr	L0c6
	jsr	L2ba
	jsr	L030
	aw	r2,r6
tt_22:	ll	0x4,r4
	lgl	r4,lrr
	aw	gl,r6
	dw1	spl,spl
tt_24:	nop	,lrr
	aw	mpl,r6
	dw1	spl,spl
tt_26:	ll	0x5,r4
	lgl	r4,lrr
	aw	gl,r6
	dw1	spl,spl
tt_28:	mw	mpl,r4,lrr
	jzf	L0d3,lrr

	jsr	L030
	aw	r4,r6
	dw1	spl,spl

; opcode 0x9b LAE - Load Address Extended
L062:	jsr	L0c6
	jsr	L2ba
	jsr	L030
	aw	r2,r6
	dw1	spl,spl
tt_42:	nop	,lrr
	aw	mpl,r6		; [mpl+r7:6] := r3:2
	w	r7,r6,rsvc
	ow	r3,r2


tt_43:	ll	0x5,r4		; [bp+r7:6] := r3:2
	lgl	r4,lrr
	aw	gl,r6
	w	r7,r6,rsvc
	ow	r3,r2


tt_44:	mw	mpl,r4,lrr
	jzf	L0d3,lrr
	jsr	L030
	aw	r6,r4
tt_61:	w	r5,r4,rsvc
	ow	r3,r2


L076:	mw	r2,r4,lrr
	jsr	L2ba
	jsr	L030
	aw	r2,r6
	w	r7,r6,rsvc
	ow	r5,r4


tt_45:	slbf	r3,r8
	srwcf	r3,r3
	aw	r6,r2
	r	r3,r2
	iw	0x0,r6
	cmb	r7,r6
	w	sph,spl,rsvc
	ob	r6,r6


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

tt_66:	mb	r4,r8
	mbf	r2,r4
	r	r7,r6
	iw	0x0,r2
	jzt	L097
L094:	srw	r3,r3
	db1	r4,r4
	jzbf	L094
L097:	jsr	L1d7
	nw	r2,r6
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


tt_23:	ll	0x4,r4
	lgl	r4,lrr
	aw	gl,r6
	mw	r6,r2
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
L0bb:	nop
tt_34:	mw	spl,r2,lrr
	aw	r6,spl
	riw1	sph,spl
	iw	0x0,r4
	jmp	L0b2


tt_62:	jsr	L030
	jmp	L0b2


; opcode 0x92 LCA - Load Constant Address
L0c3:	mw	mpl,r4,lrr
	jzf	L0d3,lrr
	jmp	L2a2


; fetch a byte operand?
L0c6:	nop			; a translation most likely happens here


; opcode 0x95 CXI - Call eXternal procedure Intermediate
L0c7:	jsr	L0c6
	mw	r6,r2
	mw	mpl,r4,lrr
	jzf	L0d3,lrr
	jmp	L298


; opcode 0x99 LSL - Load Static Link
L0cc:	mw	mpl,r4,lrr	; lm := mp
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
	cib	r5

tt_19:	r	sph,spl
	iw	0x0,r2

	nl	0x7,r6
	ab	r6,r2
	cib	r3

	r	r3,r2
	iw	0x0,r6

tt_89:	mw	r6,r2,lrr
	aw	r6,r2
	r	r3,r2
	iw	0x0,r6
tt_90:	mw	r6,r2,lrr
	aw	r2,r6
tt_80:	jzt	L0fd
	mw	r2,r4,lrr
	jsr	L12e

	r	sph,spl
	iw	0x4,r4
	aw	r4,r2,rsvc
	ow	r3,r2


L0ef:	jsr	L0c6
	jsr	L14b

	r	sph,spl
	iw	0x4,r6
	aw	r2,r6
	ow	r7,r6

	dw1	spl,spl,lrr
	w	sph,spl
	ow	r7,r6
	mwf	r4,r2
	jzt	L0fb
	jsr	L12e
L0fb:	dw1	spl,spl
	jmp	L107


L0fd:	jsr	L030
	jmp	L245


tt_83:	jnf	L189
tt_84:	tcw	r6,r6
tt_86:	nl	0x7f,r7
tt_87:	al	0x80,r7
tt_39:	nw	r2,r6
tt_38:	orw	r2,r6
tt_88:	ocw	r6,r6
tt_40:	awf	r6,r2
L107:	w	sph,spl,rsvc
	ow	r3,r2


tt_41:	swf	r2,r6
	w	sph,spl,rsvc
	ow	r7,r6


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


; possibly opcode 0x8d - DVI - DiVide Integers
tt_33:	jsr	L13e
	jmp	L11b


tt_35:	jsr	L14f
	jcf	L11d
	jmp	L166


; possibly opcode 0xcb - CHK - CHecK against subrange bounds
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
	xw	r2,r2

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
	icw1	r6,r6
tt_15:	r	r7,r6
	iw	0x0,r6
tt_85:
L163:	dw1	spl,spl
tt_97:
L164:	w	sph,spl,rsvc
	ow	r7,r6


L166:	sw	r4,r6
	jmp	L164


divide_by_zero:
	ll	0x6,r6		; raise exception 6 - divide by zero
	jmp	raise_exception


tt_64:	mw	spl,r4
	aw	r2,spl,lrr
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
	jmp	L245


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
L189:	jmp	L245


; 0xbc SRS  - build SubRange Set
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


L1c2:	mw	spl,r4
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
L1d0:	slbc	r7,r6

L1d1:	ll	0xf,r6
	nb	r2,r6
	srw	r3,r3
	srw	r3,r3
	srw	r3,r3
	srw	r3,r3
L1d7:	ll	0x0,r7
	ll	0x1,r6
	srbf	r6,r6
	mb	r8,r8
	jzbt	L1df
L1dc:	slwc	r6,r6
	db1	r8,r8
	jzbf	L1dc
L1df:	rfs


L1e0:	jzt	L189
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
	jmp	L245
	
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


L201:	jzf	L206
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
	aw	r6,spl
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


L229:	jzt	L245
	jsr	L21c
	jzf	L22d
L22c:	dw1	r2,spl
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
	aw	r6,spl
tt_77:	tl	0x1,r2
	jzbf	L296
tt_30:
L23c:	ll	0xff,r3,lrr
	slbf	r6,r2
	cmb	r3,r7
L23f:	dw1	ipcl,r2
	icw2	r6,ipcl,lrr
	srwcf	ipch,ipch
L242:	awc	r2,ipcl,lrr
	jcf	L245
	dw1	ipcl,r8

; opcode 0x9c - NOP - No OPeration
tt_10:
tt_11:
L245:	nop			; XXX does a translation happen here?


tt_75:	xwf	r2,r4
	jzf	L23c
	jmp	L296


tt_76:	xwf	r2,r4
	jzt	L23c
	jmp	L296


tt_31:	nop	,lrr
	jmp	L250


tt_78:	srbf	r2,r2,lrr
	jct	L245
L250:	slbf	r7,r3
	jmp	L23f


tt_79:	ll	0x4,r4
	lgl	r4,lrr
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
	slw	ipcl,ipcl,lrr

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


; opcode 0x97 - CPF - Call Procedure Formal
L27d:	riw1	sph,spl
	iw	0x0,r8

	ll	0x0,r4
	lgl	r4

	riw1	sph,spl
	iw	0x0,gl

	al	0x3,gl
	cib	gh

	mbf	r9,r6

	jmp	L5fc


	nop	,lrr


; opcode 0x90 LDCB - LoaD Constant Byte
L288:	ll	0x7,r4
	jmp	L28b


; opcode 0x91 LDCI - LoaD Constant Immediate
L28a:	ll	0x5,r4
L28b:	jsr	L0c6
	ll	0x4,r8
	lgl	r8
	sw	gl,ipcl
	ll	0x0,r5
	jmp	L257


; opcode 0x93 CXL - Call eXternal procedure Local
L291:	ll	0x7,r4
	jsr	L0c6
	jmp	L29c


; opcode 0x94 CXG - Call eXternal procedure Global
L294:	ll	0x5,r4,lrr
	jmp	L29c


L296:	nop	,lrr
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
	ib	0x1,r5
L2af:	ll	0x2,r2
	lgl	r2
	aw	gl,r6
L2b2:	ll	0x4,r2
	lgl	r2
	r	r7,r6
	iw	0x0,r6
	riw2	r7,r6
	iw	0x0,r2
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


; opcode 0x96 - RPU - Return from Procedure User
L2c6:	dw1	mpl,mpl		; sp := mp (adjusted)
	dw1	mpl,spl

	riw1	sph,spl		; mp := lm^.m.msdyn1
	iw	0x0,mpl
	al	0x3,mpl
	cib	mph

	ll	0x4,r8		; g = segb
	lgl	r8,lrr

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


	nop


; opcode 0x9e - BPT - Break PoinT
op_bpt:	ll	0xe,r6		; raise exception 14 - halt or breakpoint
	jmp	raise_exception


tt_63:	al	0xfd,spl
	cdb	sph
	mw	r2,r6
	mw	r4,r2


; opcode 0xbd - SWAP - SWAP top of stack with next of stack
L2e6:	w	sph,spl
	ow	r3,r2
	dw1	spl,spl
L2e9:	riw1	r7,r6
	iw	0x0,r4
	swf	r4,r2
	jnt	L245
	lgl	r8
	riw1	r7,r6
	iw	0x0,gl
	sw	r4,gl
	cwf	r2,gl
	jct	L245
	aw	r2,r6
	r	r7,r6
	iw	0x0,r6
	jmp	L250


	nop
	nop
	nop
	nop


tt_12:	al	0xff,ipcl
	cdb	ipch

tt_08:
tt_09:
tt_13:	nop
	nop

tt_58:	al	0x80,r3
tt_57:	jmp	L32f


tt_60:	jmp	L39a


tt_59:	jmp	L37d


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


; opcode 0xbe - TNC - TruNCate real
; opcode 0xbf - RND - RouND real
L315:	slwf	r2,r2
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


; dispatch opcodes 0x90..0x9f
tt_36:	ll	0x0,r7
	nl	0xf,r6
	mi	r7,r6
	jmp	L410


; dispatch opcodes 0xb8..0xbf
tt_55:	mb	r6,r4
	r	sph,spl
	iw	0x0,r6
	ll	0x0,r5
	nl	0x7,r4
	mi	r5,r4
	jmp	L420


tt_81:	ll	0x0,r7
	nl	0x7,r6
	mi	r7,r6
	jmp	L428


; jump table for opcodes 0x90..0x9f
L410:	jmp	L288	; 0x90 CPL  - Call Procedure Local
	jmp	L28a	; 0x91 CPG  - Call Procedure Global
	jmp	L0c3	; 0x92 CPI  - Call Procedure Intermediate
	jmp	L291	; 0x93 CXL  - Call eXternal procedure Local
	jmp	L294	; 0x94 CXG  - Call eXternal procedure Global
	jmp	L0c7	; 0x95 CXI  - Call eXternal procedure Intermediate
	jmp	L2c6	; 0x96 RPU  - Return From Procedure User
	jmp	L27d	; 0x97 CPF  - Call Procedure Formal
	jmp	L03a	; 0x98 LDCN - LoaD Constant Nil
	jmp	L0cc	; 0x99 LSL  - Load Static Link
	jmp	L04e	; 0x9a LDE  - LoaD word Extended
	jmp	L062	; 0x9b LAE  - Load Address Extended
	jmp	L245	; 0x9c NOP  - No OPeration
	jmp	L4f0	; 0x9d LPR  - Load Processor Register
	jmp	op_bpt	; 0x9e BPT  - Break PoinT
	jmp	L550	; 0x9f BNOT - Boolean NOT (was RBP in early releases)


; jump table for opcodes 0xb8..0xbf
L420:	jmp	L489	; 0xb8 
	jmp	L497
	jmp	L49a
	jmp	L49f
	jmp	op_srs	; 0xbc SRS  - build SubRange Set
	jmp	L2e6	; 0xbd - SWAP - SWAP top of stack with next of stack
	jmp	L315	; 0xbe - TNC - TruNCate real
	jmp	L315	; 0xbf - RND - RouND real


L428:	jmp	L0ef
	jmp	L076
	jmp	L1c2
	jmp	L1e0
	jmp	L201
	jmp	L229
	jmp	L510
	jmp	L538


tt_46:	swf	r2,r6
L431:	jzt	L4c3
	jmp	L4bd


tt_47:	swf	r2,r6
	jzf	L4c3
	jmp	L4bd


tt_48:	cwf	r6,r2
	jvf	L447
	jmp	L446


tt_49:	cwf	r2,r6
	jvf	L447
	jmp	L449


tt_70:	jsr	L44c
	jmp	L4bd


	nop

tt_71:	jsr	L44c
	jnbt	L446
	jct	L446
	jmp	L449


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


tt_50:	cwf	r6,r2
	jcf	L4c3
	jmp	L4bd


tt_51:	cwf	r2,r6
	jcf	L4c3
	jmp	L4bd


tt_52:	jsr	L473
	cw	r4,gl
	jzbf	L4b6
	jzf	L484
	cb	r7,r6
	jzbt	L4c2
	jc8t	L490
	jmp	L46c


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
	db1f	r8,r8
L489:	jsr	L473
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


L497:	mw	r6,r4,lrr
	jsr	L4a4
	jmp	L431


L49a:	mw	r6,r4,lrr
	jsr	L4a4
	jcf	L4c3
	jmp	L4bd


	nop


L49f:	mw	r6,r4,lrr
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
	iw	0x0,mpl
L4b6:	cb	r7,r6
	jc8t	L4ba
	sb	r6,r7
L4b9:	ab	r7,r8
L4ba:	ab	r8,spl
	cib	sph
L4bc:	dw1	spl,spl
L4bd:	ll	0x0,r6
	ll	0x0,r7
L4bf:	sb	r6,r7
	ab	r7,spl
	cib	sph
L4c2:	dw1	spl,spl
L4c3:	ll	0x1,r6
	ll	0x0,r7
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


; possibly opcode 0xd1 SPR - Store Processor Register
L4dd:	dw1	ipcl,spl
	jsr	L2b8
	mw	r2,gl
	jmp	L55b


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


; opcode 0x9d LPR - Load Processor Register
L4f0:	r	sph,spl		; r5:4 = [sp]
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


; int 3
tt_03:	ll	0x8,r2
	jmp	L507

; int 2
tt_02:	ll	0x4,r2
	jmp	L507

; int 1
tt_01:	ll	0x2,r2
	jmp	L507

; int 0
tt_00:	ll	0x1,r2		; r2 := 1

L507:	ll	0xfc,r5		; r5:4 := 0xfc40
	ll	0x40,r4
	w	r5,r4		; [0xfc40] := interrupt bit to clear
	ob	r2,r2

	ll	0x60,r4		; r5:4 := 0xfc60

	ra	r5,r4		; r7:6 := [0xfc60] ; read interrupt vector
	iw	0x0,r6

	r	r7,r6		; r3:2 := [r7:6]
	iw	0x0,r2

L510:	riw1	r3,r2		; r5:4 := [r3:2++]
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
L51b:	jmp	L245

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


L538:	riw1	r3,r2		; r5:4 := [r3:2]
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


L550:	r	sph,spl		; r6 := [sp], lower byte, RMW
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
	lgl	r2

L587:	ll	0x3,r9		; g := rq
	lgl	r9

	mw	gl,r6		; r7:6 := rq

	cl	0xfc,gh		; is rq nil?
	jzbt	L58e

	mw	gl,r2
	jmp	L5d1

tt_07:
L58e:	lgl	r2		; rq := r7:6
	mw	r6,gl

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
	slw	ipcl,ipcl
L5af:	wiw2	r9,r8
	ow	ipch,ipcl
; XXX does a translation occur here?


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
