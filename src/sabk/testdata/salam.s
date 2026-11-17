// The R8 program of spec 024, written by hand: the reference `SabkTests` (c) assembles with `clang -c` to compare the
// section and symbol listings of sabk's tmp/sabk/salam.o against. Instruction choices may differ from sabk's; the
// sections, their attributes and the symbol names and kinds may not.
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_main
	.p2align	2
_main:
	stp	x29, x30, [sp, #-16]!
	mov	x29, sp
	mov	w0, #0
	adrp	x1, str0@PAGE
	add	x1, x1, str0@PAGEOFF
	mov	x2, #13
	bl	_byn_print
	bl	_byn_stdout_flush
	adrp	x16, _counter@PAGE
	add	x16, x16, _counter@PAGEOFF
	ldr	x9, [x16]
	add	x9, x9, #7
	str	x9, [x16]
	ldr	x0, [x16]
	ldp	x29, x30, [sp], #16
	ret

	.section	__TEXT,__cstring,cstring_literals
str0:
	.asciz	"Salam, world!"

	.section	__DATA,__data
	.p2align	3
_counter:
	.quad	35
