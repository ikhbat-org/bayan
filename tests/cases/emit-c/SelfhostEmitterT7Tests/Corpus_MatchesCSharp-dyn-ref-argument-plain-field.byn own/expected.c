false bynh_chk_claim_dyn_main__IC bynh_chk_set_dyn_main__IC bynh_chk_move_dyn_main__IC bynh_chk_ret_dyn_main__IC
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
true bynh_chk_claim_main__B bynh_chk_set_main__B bynh_chk_move_main__B bynh_chk_ret_main__B
false bynh_chk_claim_span_i64 bynh_chk_set_span_i64 bynh_chk_move_span_i64 bynh_chk_ret_span_i64
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
helper bynh_chk_claim_dyn_main__IC
static void bynh_chk_claim_dyn_main__IC(byn_dyn_main__IC* p, const char* file, int line) {
}
helper bynh_chk_set_dyn_main__IC
static byn_dyn_main__IC bynh_chk_set_dyn_main__IC(byn_dyn_main__IC* p, byn_dyn_main__IC v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_dyn_main__IC(p, file, line);
    return v;
}
helper bynh_chk_move_dyn_main__IC
static byn_dyn_main__IC* bynh_chk_move_dyn_main__IC(byn_dyn_main__IC* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "dyn ref IC", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_dyn_main__IC
static byn_dyn_main__IC bynh_chk_ret_dyn_main__IC(byn_dyn_main__IC v) {
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
helper bynh_chk_claim_main__B
static void bynh_chk_claim_main__B(bynt_main__B* p, const char* file, int line) {
    byn_own_claim((*p).items.ptr, &(*p).items, "List<i64>", file, line);
}
helper bynh_chk_set_main__B
static bynt_main__B bynh_chk_set_main__B(bynt_main__B* p, bynt_main__B v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).items.ptr, &(*p).items);
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__B(p, file, line);
    return v;
}
helper bynh_chk_move_main__B
static bynt_main__B* bynh_chk_move_main__B(bynt_main__B* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "B", file, line);
    byn_own_release((*p).items.ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__B
static bynt_main__B bynh_chk_ret_main__B(bynt_main__B v) {
    byn_own_release(v.items.ptr);
    return v;
}
helper bynh_chk_claim_span_i64
static void bynh_chk_claim_span_i64(bynt_span_i64* p, const char* file, int line) {
}
helper bynh_chk_set_span_i64
static bynt_span_i64 bynh_chk_set_span_i64(bynt_span_i64* p, bynt_span_i64 v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_span_i64(p, file, line);
    return v;
}
helper bynh_chk_move_span_i64
static bynt_span_i64* bynh_chk_move_span_i64(bynt_span_i64* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "ReadOnlySpan<i64>", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_span_i64
static bynt_span_i64 bynh_chk_ret_span_i64(bynt_span_i64 v) {
    return v;
}