false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_main__Point bynh_chk_set_main__Point bynh_chk_move_main__Point bynh_chk_ret_main__Point
false bynh_chk_claim_main__Point bynh_chk_set_main__Point bynh_chk_move_main__Point bynh_chk_ret_main__Point
false bynh_chk_claim_main__Point bynh_chk_set_main__Point bynh_chk_move_main__Point bynh_chk_ret_main__Point
false bynh_chk_claim_main__Line bynh_chk_set_main__Line bynh_chk_move_main__Line bynh_chk_ret_main__Line
false bynh_chk_claim_tup2_str_i32 bynh_chk_set_tup2_str_i32 bynh_chk_move_tup2_str_i32 bynh_chk_ret_tup2_str_i32
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_main__Point bynh_chk_set_main__Point bynh_chk_move_main__Point bynh_chk_ret_main__Point
false bynh_chk_claim_main__Point bynh_chk_set_main__Point bynh_chk_move_main__Point bynh_chk_ret_main__Point
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
true bynh_chk_claim_strbuf bynh_chk_set_strbuf bynh_chk_move_strbuf bynh_chk_ret_strbuf
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
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
helper bynh_chk_claim_main__Point
static void bynh_chk_claim_main__Point(bynt_main__Point* p, const char* file, int line) {
}
helper bynh_chk_set_main__Point
static bynt_main__Point bynh_chk_set_main__Point(bynt_main__Point* p, bynt_main__Point v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Point(p, file, line);
    return v;
}
helper bynh_chk_move_main__Point
static bynt_main__Point* bynh_chk_move_main__Point(bynt_main__Point* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Point", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Point
static bynt_main__Point bynh_chk_ret_main__Point(bynt_main__Point v) {
    return v;
}
helper bynh_chk_claim_main__Line
static void bynh_chk_claim_main__Line(bynt_main__Line* p, const char* file, int line) {
}
helper bynh_chk_set_main__Line
static bynt_main__Line bynh_chk_set_main__Line(bynt_main__Line* p, bynt_main__Line v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Line(p, file, line);
    return v;
}
helper bynh_chk_move_main__Line
static bynt_main__Line* bynh_chk_move_main__Line(bynt_main__Line* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Line", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Line
static bynt_main__Line bynh_chk_ret_main__Line(bynt_main__Line v) {
    return v;
}
helper bynh_chk_claim_tup2_str_i32
static void bynh_chk_claim_tup2_str_i32(bynt_tup2_str_i32* p, const char* file, int line) {
}
helper bynh_chk_set_tup2_str_i32
static bynt_tup2_str_i32 bynh_chk_set_tup2_str_i32(bynt_tup2_str_i32* p, bynt_tup2_str_i32 v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_tup2_str_i32(p, file, line);
    return v;
}
helper bynh_chk_move_tup2_str_i32
static bynt_tup2_str_i32* bynh_chk_move_tup2_str_i32(bynt_tup2_str_i32* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "(string name, i32 age)", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_tup2_str_i32
static bynt_tup2_str_i32 bynh_chk_ret_tup2_str_i32(bynt_tup2_str_i32 v) {
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
helper bynh_chk_claim_strbuf
static void bynh_chk_claim_strbuf(byn_writer* p, const char* file, int line) {
    byn_own_claim(((*p).mode == BYN_WRITE_GROW ? (*p).buf : NULL), &(*p), "StrBuf", file, line);
}
helper bynh_chk_set_strbuf
static byn_writer bynh_chk_set_strbuf(byn_writer* p, byn_writer v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop(((*p).mode == BYN_WRITE_GROW ? (*p).buf : NULL), &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_strbuf(p, file, line);
    return v;
}
helper bynh_chk_move_strbuf
static byn_writer* bynh_chk_move_strbuf(byn_writer* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "StrBuf", file, line);
    byn_own_release(((*p).mode == BYN_WRITE_GROW ? (*p).buf : NULL));
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_strbuf
static byn_writer bynh_chk_ret_strbuf(byn_writer v) {
    byn_own_release((v.mode == BYN_WRITE_GROW ? v.buf : NULL));
    return v;
}