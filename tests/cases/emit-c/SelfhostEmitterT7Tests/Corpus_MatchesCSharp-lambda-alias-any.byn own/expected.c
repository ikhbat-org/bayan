false bynh_chk_claim_span_i32 bynh_chk_set_span_i32 bynh_chk_move_span_i32 bynh_chk_ret_span_i32
false bynh_chk_claim_fn1_i32_bool bynh_chk_set_fn1_i32_bool bynh_chk_move_fn1_i32_bool bynh_chk_ret_fn1_i32_bool
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_span_i32 bynh_chk_set_span_i32 bynh_chk_move_span_i32 bynh_chk_ret_span_i32
false bynh_chk_claim_span_i32 bynh_chk_set_span_i32 bynh_chk_move_span_i32 bynh_chk_ret_span_i32
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
helper bynh_chk_claim_span_i32
static void bynh_chk_claim_span_i32(bynt_span_i32* p, const char* file, int line) {
}
helper bynh_chk_set_span_i32
static bynt_span_i32 bynh_chk_set_span_i32(bynt_span_i32* p, bynt_span_i32 v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_span_i32(p, file, line);
    return v;
}
helper bynh_chk_move_span_i32
static bynt_span_i32* bynh_chk_move_span_i32(bynt_span_i32* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Span<i32>", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_span_i32
static bynt_span_i32 bynh_chk_ret_span_i32(bynt_span_i32 v) {
    return v;
}
helper bynh_chk_claim_fn1_i32_bool
static void bynh_chk_claim_fn1_i32_bool(bynt_fn1_i32_bool* p, const char* file, int line) {
}
helper bynh_chk_set_fn1_i32_bool
static bynt_fn1_i32_bool bynh_chk_set_fn1_i32_bool(bynt_fn1_i32_bool* p, bynt_fn1_i32_bool v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_fn1_i32_bool(p, file, line);
    return v;
}
helper bynh_chk_move_fn1_i32_bool
static bynt_fn1_i32_bool* bynh_chk_move_fn1_i32_bool(bynt_fn1_i32_bool* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "i32 -> bool", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_fn1_i32_bool
static bynt_fn1_i32_bool bynh_chk_ret_fn1_i32_bool(bynt_fn1_i32_bool v) {
    return v;
}
helper bynh_chk_claim_bool
static void bynh_chk_claim_bool(bool* p, const char* file, int line) {
}
helper bynh_chk_set_bool
static bool bynh_chk_set_bool(bool* p, bool v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_bool(p, file, line);
    return v;
}
helper bynh_chk_move_bool
static bool* bynh_chk_move_bool(bool* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "bool", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_bool
static bool bynh_chk_ret_bool(bool v) {
    return v;
}
helper bynh_chk_claim_i32
static void bynh_chk_claim_i32(int32_t* p, const char* file, int line) {
}
helper bynh_chk_set_i32
static int32_t bynh_chk_set_i32(int32_t* p, int32_t v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_i32(p, file, line);
    return v;
}
helper bynh_chk_move_i32
static int32_t* bynh_chk_move_i32(int32_t* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "i32", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_i32
static int32_t bynh_chk_ret_i32(int32_t v) {
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