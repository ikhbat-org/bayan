// The module the Mach-O writer test builds through writeObject; scripts/sabk/record-macho.sh assembles it with clang
// and records the object's header, load commands, relocations and symbols into macho-expected.txt.
    .section __TEXT,__text,regular,pure_instructions
    .globl _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-16]!
    adrp x1, _msg@PAGE
    add x1, x1, _msg@PAGEOFF
    bl _byn_print
    ldp x29, x30, [sp], #16
    ret
_helper:
    ret

    .section __TEXT,__cstring,cstring_literals
_msg:
    .asciz "Salam, world!"

    .section __DATA,__data
    .p2align 3
_ptr:
    .quad _byn_print
