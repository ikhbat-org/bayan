// Phase-1 sabk instruction subset, one instruction per line, each preceded by its '// form:' line.
// Input of scripts/sabk/record-encodings.sh; expected bytes come only from the assembler.
.text
.p2align 2
// form: movz-x
    movz x0, #0
// form: movz-w
    movz w1, #1
// form: movz-x-lsl0
    movz x2, #0, lsl #0
// form: movz-x-max-lsl0
    movz x3, #65535, lsl #0
// form: movk-x-lsl0
    movk x4, #0, lsl #0
// form: movk-x-max-lsl0
    movk x5, #65535, lsl #0
// form: movz-x-lsl16
    movz x2, #0, lsl #16
// form: movz-x-max-lsl16
    movz x3, #65535, lsl #16
// form: movk-x-lsl16
    movk x4, #0, lsl #16
// form: movk-x-max-lsl16
    movk x5, #65535, lsl #16
// form: movz-x-lsl32
    movz x2, #0, lsl #32
// form: movz-x-max-lsl32
    movz x3, #65535, lsl #32
// form: movk-x-lsl32
    movk x4, #0, lsl #32
// form: movk-x-max-lsl32
    movk x5, #65535, lsl #32
// form: movz-x-lsl48
    movz x2, #0, lsl #48
// form: movz-x-max-lsl48
    movz x3, #65535, lsl #48
// form: movk-x-lsl48
    movk x4, #0, lsl #48
// form: movk-x-max-lsl48
    movk x5, #65535, lsl #48
// form: movz-w-lsl0
    movz w6, #0, lsl #0
// form: movz-w-max-lsl0
    movz w7, #65535, lsl #0
// form: movk-w-lsl0
    movk w8, #0, lsl #0
// form: movk-w-max-lsl0
    movk w9, #65535, lsl #0
// form: movz-w-lsl16
    movz w6, #0, lsl #16
// form: movz-w-max-lsl16
    movz w7, #65535, lsl #16
// form: movk-w-lsl16
    movk w8, #0, lsl #16
// form: movk-w-max-lsl16
    movk w9, #65535, lsl #16
// form: mov-reg-x
    mov x10, x11
// form: mov-reg-w
    mov w12, w13
// form: mov-to-sp
    mov sp, x14
// form: mov-from-sp
    mov x15, sp
// form: add-imm-x-0-l0
    add x16, x17, #0
// form: add-imm-w-0-l0
    add w16, w17, #0
// form: sub-imm-x-0-l0
    sub x19, sp, #0
// form: sub-imm-w-0-l0
    sub w19, w20, #0
// form: add-imm-x-0-l12
    add x16, x17, #0, lsl #12
// form: add-imm-w-0-l12
    add w16, w17, #0, lsl #12
// form: sub-imm-x-0-l12
    sub x19, sp, #0, lsl #12
// form: sub-imm-w-0-l12
    sub w19, w20, #0, lsl #12
// form: add-imm-x-4095-l0
    add x16, x17, #4095
// form: add-imm-w-4095-l0
    add w16, w17, #4095
// form: sub-imm-x-4095-l0
    sub x19, sp, #4095
// form: sub-imm-w-4095-l0
    sub w19, w20, #4095
// form: add-imm-x-4095-l12
    add x16, x17, #4095, lsl #12
// form: add-imm-w-4095-l12
    add w16, w17, #4095, lsl #12
// form: sub-imm-x-4095-l12
    sub x19, sp, #4095, lsl #12
// form: sub-imm-w-4095-l12
    sub w19, w20, #4095, lsl #12
// form: add-reg-x
    add x21, x22, x23
// form: add-reg-w
    add w21, w22, w23
// form: add-reg-x-lsl
    add x21, x22, x23, lsl #3
// form: add-reg-x-lsr
    add x21, x22, x23, lsr #5
// form: add-reg-x-asr
    add x21, x22, x23, asr #7
// form: sub-reg-x
    sub x24, x25, x26
// form: sub-reg-w
    sub w24, w25, w26
// form: subs-reg-x
    subs x27, x28, x29
// form: subs-reg-w
    subs w27, w28, w29
// form: subs-imm-x
    subs x0, x1, #4095
// form: subs-imm-w
    subs w0, w1, #1
// form: cmp-reg-x
    cmp x2, x30
// form: cmp-reg-w
    cmp w2, w30
// form: cmp-imm-x
    cmp x3, #4095
// form: cmp-imm-w
    cmp w3, #0
// form: mul-x
    mul x4, x5, x6
// form: mul-w
    mul w4, w5, w6
// form: sdiv-x
    sdiv x7, x8, x9
// form: sdiv-w
    sdiv w7, w8, w9
// form: msub-x
    msub x10, x11, x12, x13
// form: msub-w
    msub w10, w11, w12, w13
// form: neg-x
    neg x14, x15
// form: neg-w
    neg w14, w15
// form: and-x
    and x16, x17, x18
// form: and-w
    and w16, w17, w18
// form: and-x-lsl
    and x16, x17, x18, lsl #4
// form: and-w-lsr
    and w16, w17, w18, lsr #3
// form: orr-x
    orr x16, x17, x18
// form: orr-w
    orr w16, w17, w18
// form: orr-x-lsl
    orr x16, x17, x18, lsl #4
// form: orr-w-lsr
    orr w16, w17, w18, lsr #3
// form: eor-x
    eor x16, x17, x18
// form: eor-w
    eor w16, w17, w18
// form: eor-x-lsl
    eor x16, x17, x18, lsl #4
// form: eor-w-lsr
    eor w16, w17, w18, lsr #3
// form: cset-x-eq
    cset x19, eq
// form: cset-w-eq
    cset w19, eq
// form: csel-x-eq
    csel x20, x21, x22, eq
// form: csel-w-eq
    csel w20, w21, w22, eq
// form: cset-x-ne
    cset x19, ne
// form: cset-w-ne
    cset w19, ne
// form: csel-x-ne
    csel x20, x21, x22, ne
// form: csel-w-ne
    csel w20, w21, w22, ne
// form: cset-x-hs
    cset x19, hs
// form: cset-w-hs
    cset w19, hs
// form: csel-x-hs
    csel x20, x21, x22, hs
// form: csel-w-hs
    csel w20, w21, w22, hs
// form: cset-x-lo
    cset x19, lo
// form: cset-w-lo
    cset w19, lo
// form: csel-x-lo
    csel x20, x21, x22, lo
// form: csel-w-lo
    csel w20, w21, w22, lo
// form: cset-x-mi
    cset x19, mi
// form: cset-w-mi
    cset w19, mi
// form: csel-x-mi
    csel x20, x21, x22, mi
// form: csel-w-mi
    csel w20, w21, w22, mi
// form: cset-x-pl
    cset x19, pl
// form: cset-w-pl
    cset w19, pl
// form: csel-x-pl
    csel x20, x21, x22, pl
// form: csel-w-pl
    csel w20, w21, w22, pl
// form: cset-x-vs
    cset x19, vs
// form: cset-w-vs
    cset w19, vs
// form: csel-x-vs
    csel x20, x21, x22, vs
// form: csel-w-vs
    csel w20, w21, w22, vs
// form: cset-x-vc
    cset x19, vc
// form: cset-w-vc
    cset w19, vc
// form: csel-x-vc
    csel x20, x21, x22, vc
// form: csel-w-vc
    csel w20, w21, w22, vc
// form: cset-x-hi
    cset x19, hi
// form: cset-w-hi
    cset w19, hi
// form: csel-x-hi
    csel x20, x21, x22, hi
// form: csel-w-hi
    csel w20, w21, w22, hi
// form: cset-x-ls
    cset x19, ls
// form: cset-w-ls
    cset w19, ls
// form: csel-x-ls
    csel x20, x21, x22, ls
// form: csel-w-ls
    csel w20, w21, w22, ls
// form: cset-x-ge
    cset x19, ge
// form: cset-w-ge
    cset w19, ge
// form: csel-x-ge
    csel x20, x21, x22, ge
// form: csel-w-ge
    csel w20, w21, w22, ge
// form: cset-x-lt
    cset x19, lt
// form: cset-w-lt
    cset w19, lt
// form: csel-x-lt
    csel x20, x21, x22, lt
// form: csel-w-lt
    csel w20, w21, w22, lt
// form: cset-x-gt
    cset x19, gt
// form: cset-w-gt
    cset w19, gt
// form: csel-x-gt
    csel x20, x21, x22, gt
// form: csel-w-gt
    csel w20, w21, w22, gt
// form: cset-x-le
    cset x19, le
// form: cset-w-le
    cset w19, le
// form: csel-x-le
    csel x20, x21, x22, le
// form: csel-w-le
    csel w20, w21, w22, le
// form: ldr-x-0
    ldr x0, [x1]
// form: ldr-x-max
    ldr x0, [x1, #32760]
// form: ldr-w-0
    ldr w0, [x1]
// form: ldr-w-max
    ldr w0, [x1, #16380]
// form: str-x-0
    str x2, [sp]
// form: str-x-max
    str x2, [sp, #32760]
// form: str-w-0
    str w2, [x3]
// form: str-w-max
    str w2, [x3, #16380]
// form: ldur-x-min
    ldur x4, [x5, #-256]
// form: ldur-x-max
    ldur x4, [x5, #255]
// form: ldur-w-min
    ldur w4, [x5, #-256]
// form: ldur-w-max
    ldur w4, [x5, #255]
// form: stur-x-min
    stur x6, [x7, #-256]
// form: stur-x-max
    stur x6, [x7, #255]
// form: stur-w-min
    stur w6, [x7, #-256]
// form: stur-w-max
    stur w6, [x7, #255]
// form: stp-x-off-min
    stp x29, x30, [sp, #-512]
// form: stp-x-off-max
    stp x29, x30, [sp, #504]
// form: stp-x-pre
    stp x29, x30, [sp, #-16]!
// form: stp-x-pre-min
    stp x19, x20, [sp, #-512]!
// form: stp-x-post
    stp x19, x20, [sp], #504
// form: ldp-x-off-min
    ldp x29, x30, [sp, #-512]
// form: ldp-x-off-max
    ldp x29, x30, [sp, #504]
// form: ldp-x-pre
    ldp x21, x22, [sp, #-16]!
// form: ldp-x-post
    ldp x29, x30, [sp], #16
// form: ldp-x-post-max
    ldp x23, x24, [x25], #504
// form: b-fwd
    b Lfwd
// form: nop-a
    nop
Lfwd:
Lback:
// form: nop-b
    nop
// form: b-back
    b Lback
// form: bl-back
    bl Lback
// form: bl-fwd
    bl Lfwd2
// form: nop-c
    nop
Lfwd2:
// form: b-cond-eq
    b.eq Lback
// form: b-cond-ne
    b.ne Lback
// form: b-cond-hs
    b.hs Lback
// form: b-cond-lo
    b.lo Lback
// form: b-cond-mi
    b.mi Lback
// form: b-cond-pl
    b.pl Lback
// form: b-cond-vs
    b.vs Lback
// form: b-cond-vc
    b.vc Lback
// form: b-cond-hi
    b.hi Lback
// form: b-cond-ls
    b.ls Lback
// form: b-cond-ge
    b.ge Lback
// form: b-cond-lt
    b.lt Lback
// form: b-cond-gt
    b.gt Lback
// form: b-cond-le
    b.le Lback
// form: cbz-x-back
    cbz x0, Lback
// form: cbz-w-fwd
    cbz w1, Lfwd3
// form: cbnz-x-back
    cbnz x2, Lback
// form: cbnz-w-fwd
    cbnz w3, Lfwd3
// form: nop-d
    nop
Lfwd3:
// form: br
    br x4
// form: blr
    blr x5
// form: ret
    ret
// form: ret-x
    ret x6
// form: adrp-reloc
    adrp x0, _ext@PAGE
// form: add-pageoff-reloc
    add x0, x0, _ext@PAGEOFF
// form: adr-fwd
    adr x1, Lfwd4
// form: nop-e
    nop
Lfwd4:
// form: adr-back
    adr x2, Lfwd4
// form: add-rd-x0
    add x0, x0, x1
// form: add-rn-x0
    add x2, x0, x3
// form: add-rm-x0
    add x4, x5, x0
// form: add-rd-w0
    add w0, w0, w1
// form: add-rd-x1
    add x1, x0, x1
// form: add-rn-x1
    add x2, x1, x3
// form: add-rm-x1
    add x4, x5, x1
// form: add-rd-w1
    add w1, w0, w1
// form: add-rd-x2
    add x2, x0, x1
// form: add-rn-x2
    add x2, x2, x3
// form: add-rm-x2
    add x4, x5, x2
// form: add-rd-w2
    add w2, w0, w1
// form: add-rd-x3
    add x3, x0, x1
// form: add-rn-x3
    add x2, x3, x3
// form: add-rm-x3
    add x4, x5, x3
// form: add-rd-w3
    add w3, w0, w1
// form: add-rd-x4
    add x4, x0, x1
// form: add-rn-x4
    add x2, x4, x3
// form: add-rm-x4
    add x4, x5, x4
// form: add-rd-w4
    add w4, w0, w1
// form: add-rd-x5
    add x5, x0, x1
// form: add-rn-x5
    add x2, x5, x3
// form: add-rm-x5
    add x4, x5, x5
// form: add-rd-w5
    add w5, w0, w1
// form: add-rd-x6
    add x6, x0, x1
// form: add-rn-x6
    add x2, x6, x3
// form: add-rm-x6
    add x4, x5, x6
// form: add-rd-w6
    add w6, w0, w1
// form: add-rd-x7
    add x7, x0, x1
// form: add-rn-x7
    add x2, x7, x3
// form: add-rm-x7
    add x4, x5, x7
// form: add-rd-w7
    add w7, w0, w1
// form: add-rd-x8
    add x8, x0, x1
// form: add-rn-x8
    add x2, x8, x3
// form: add-rm-x8
    add x4, x5, x8
// form: add-rd-w8
    add w8, w0, w1
// form: add-rd-x9
    add x9, x0, x1
// form: add-rn-x9
    add x2, x9, x3
// form: add-rm-x9
    add x4, x5, x9
// form: add-rd-w9
    add w9, w0, w1
// form: add-rd-x10
    add x10, x0, x1
// form: add-rn-x10
    add x2, x10, x3
// form: add-rm-x10
    add x4, x5, x10
// form: add-rd-w10
    add w10, w0, w1
// form: add-rd-x11
    add x11, x0, x1
// form: add-rn-x11
    add x2, x11, x3
// form: add-rm-x11
    add x4, x5, x11
// form: add-rd-w11
    add w11, w0, w1
// form: add-rd-x12
    add x12, x0, x1
// form: add-rn-x12
    add x2, x12, x3
// form: add-rm-x12
    add x4, x5, x12
// form: add-rd-w12
    add w12, w0, w1
// form: add-rd-x13
    add x13, x0, x1
// form: add-rn-x13
    add x2, x13, x3
// form: add-rm-x13
    add x4, x5, x13
// form: add-rd-w13
    add w13, w0, w1
// form: add-rd-x14
    add x14, x0, x1
// form: add-rn-x14
    add x2, x14, x3
// form: add-rm-x14
    add x4, x5, x14
// form: add-rd-w14
    add w14, w0, w1
// form: add-rd-x15
    add x15, x0, x1
// form: add-rn-x15
    add x2, x15, x3
// form: add-rm-x15
    add x4, x5, x15
// form: add-rd-w15
    add w15, w0, w1
// form: add-rd-x16
    add x16, x0, x1
// form: add-rn-x16
    add x2, x16, x3
// form: add-rm-x16
    add x4, x5, x16
// form: add-rd-w16
    add w16, w0, w1
// form: add-rd-x17
    add x17, x0, x1
// form: add-rn-x17
    add x2, x17, x3
// form: add-rm-x17
    add x4, x5, x17
// form: add-rd-w17
    add w17, w0, w1
// form: add-rd-x18
    add x18, x0, x1
// form: add-rn-x18
    add x2, x18, x3
// form: add-rm-x18
    add x4, x5, x18
// form: add-rd-w18
    add w18, w0, w1
// form: add-rd-x19
    add x19, x0, x1
// form: add-rn-x19
    add x2, x19, x3
// form: add-rm-x19
    add x4, x5, x19
// form: add-rd-w19
    add w19, w0, w1
// form: add-rd-x20
    add x20, x0, x1
// form: add-rn-x20
    add x2, x20, x3
// form: add-rm-x20
    add x4, x5, x20
// form: add-rd-w20
    add w20, w0, w1
// form: add-rd-x21
    add x21, x0, x1
// form: add-rn-x21
    add x2, x21, x3
// form: add-rm-x21
    add x4, x5, x21
// form: add-rd-w21
    add w21, w0, w1
// form: add-rd-x22
    add x22, x0, x1
// form: add-rn-x22
    add x2, x22, x3
// form: add-rm-x22
    add x4, x5, x22
// form: add-rd-w22
    add w22, w0, w1
// form: add-rd-x23
    add x23, x0, x1
// form: add-rn-x23
    add x2, x23, x3
// form: add-rm-x23
    add x4, x5, x23
// form: add-rd-w23
    add w23, w0, w1
// form: add-rd-x24
    add x24, x0, x1
// form: add-rn-x24
    add x2, x24, x3
// form: add-rm-x24
    add x4, x5, x24
// form: add-rd-w24
    add w24, w0, w1
// form: add-rd-x25
    add x25, x0, x1
// form: add-rn-x25
    add x2, x25, x3
// form: add-rm-x25
    add x4, x5, x25
// form: add-rd-w25
    add w25, w0, w1
// form: add-rd-x26
    add x26, x0, x1
// form: add-rn-x26
    add x2, x26, x3
// form: add-rm-x26
    add x4, x5, x26
// form: add-rd-w26
    add w26, w0, w1
// form: add-rd-x27
    add x27, x0, x1
// form: add-rn-x27
    add x2, x27, x3
// form: add-rm-x27
    add x4, x5, x27
// form: add-rd-w27
    add w27, w0, w1
// form: add-rd-x28
    add x28, x0, x1
// form: add-rn-x28
    add x2, x28, x3
// form: add-rm-x28
    add x4, x5, x28
// form: add-rd-w28
    add w28, w0, w1
// form: add-rd-x29
    add x29, x0, x1
// form: add-rn-x29
    add x2, x29, x3
// form: add-rm-x29
    add x4, x5, x29
// form: add-rd-w29
    add w29, w0, w1
// form: add-rd-x30
    add x30, x0, x1
// form: add-rn-x30
    add x2, x30, x3
// form: add-rm-x30
    add x4, x5, x30
// form: add-rd-w30
    add w30, w0, w1
