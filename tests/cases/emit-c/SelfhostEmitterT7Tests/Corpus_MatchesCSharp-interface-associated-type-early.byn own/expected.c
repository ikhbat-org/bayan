false bynh_chk_claim_main__Holder__main__Ints bynh_chk_set_main__Holder__main__Ints bynh_chk_move_main__Holder__main__Ints bynh_chk_ret_main__Holder__main__Ints
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_main__Outer bynh_chk_set_main__Outer bynh_chk_move_main__Outer bynh_chk_ret_main__Outer
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
helper bynh_chk_claim_main__Holder__main__Ints
static void bynh_chk_claim_main__Holder__main__Ints(bynt_main__Holder__main__Ints* p, const char* file, int line) {
}
helper bynh_chk_set_main__Holder__main__Ints
static bynt_main__Holder__main__Ints bynh_chk_set_main__Holder__main__Ints(bynt_main__Holder__main__Ints* p, bynt_main__Holder__main__Ints v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Holder__main__Ints(p, file, line);
    return v;
}
helper bynh_chk_move_main__Holder__main__Ints
static bynt_main__Holder__main__Ints* bynh_chk_move_main__Holder__main__Ints(bynt_main__Holder__main__Ints* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Holder<Ints>", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Holder__main__Ints
static bynt_main__Holder__main__Ints bynh_chk_ret_main__Holder__main__Ints(bynt_main__Holder__main__Ints v) {
    return v;
}
helper bynh_chk_claim_void
static void bynh_chk_claim_void(void* p, const char* file, int line) {
}
helper bynh_chk_set_void
static void bynh_chk_set_void(void* p, void v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_void(p, file, line);
    return v;
}
helper bynh_chk_move_void
static void* bynh_chk_move_void(void* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "void", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_void
static void bynh_chk_ret_void(void v) {
    return v;
}
helper bynh_chk_claim_main__Outer
static void bynh_chk_claim_main__Outer(bynt_main__Outer* p, const char* file, int line) {
}
helper bynh_chk_set_main__Outer
static bynt_main__Outer bynh_chk_set_main__Outer(bynt_main__Outer* p, bynt_main__Outer v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Outer(p, file, line);
    return v;
}
helper bynh_chk_move_main__Outer
static bynt_main__Outer* bynh_chk_move_main__Outer(bynt_main__Outer* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Outer", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Outer
static bynt_main__Outer bynh_chk_ret_main__Outer(bynt_main__Outer v) {
    return v;
}
helper bynh_chk_claim_i64
static void bynh_chk_claim_i64(int64_t* p, const char* file, int line) {
}
helper bynh_chk_set_i64
static int64_t bynh_chk_set_i64(int64_t* p, int64_t v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_i64(p, file, line);
    return v;
}
helper bynh_chk_move_i64
static int64_t* bynh_chk_move_i64(int64_t* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "i64", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_i64
static int64_t bynh_chk_ret_i64(int64_t v) {
    return v;
}