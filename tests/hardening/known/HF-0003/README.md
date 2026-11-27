# HF-0003: `List.sort` swaps elements a byte at a time, which Fil-C rejects for pointer-carrying elements

Built with the Fil-C 0.687 clang (`scripts/hardening/filc.sh --only run/list-sort`, wp1 WSL, 507c90184), sorting a
`List<string>` stops with `filc safety error: cannot read pointer with ptr < lower` in `memcmp`, from `byn_str_cmp` ←
`bynh_less_str` ← `byn_sort`. `byn_sort_reverse` (`runtime/bayan-rt.c`) swaps elements through a `uint8_t` loop; ISO C allows
that byte copy, but Fil-C keeps a pointer's capability only when it is copied whole (a pointer-sized load/store or `memcpy`),
so each swapped `byn_str.ptr` loses the bounds of its string. `main.byn` is a copy of `tests/cases/run/list-sort.byn`; native builds print its golden `.stdout`.
