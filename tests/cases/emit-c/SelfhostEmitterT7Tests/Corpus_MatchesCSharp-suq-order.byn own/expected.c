false bynh_chk_claim_main__Currency bynh_chk_set_main__Currency bynh_chk_move_main__Currency bynh_chk_ret_main__Currency
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_err bynh_chk_set_err bynh_chk_move_err bynh_chk_ret_err
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_main__Line bynh_chk_set_main__Line bynh_chk_move_main__Line bynh_chk_ret_main__Line
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
true bynh_chk_claim_main__Order bynh_chk_set_main__Order bynh_chk_move_main__Order bynh_chk_ret_main__Order
true bynh_chk_claim_main__Order bynh_chk_set_main__Order bynh_chk_move_main__Order bynh_chk_ret_main__Order
true bynh_chk_claim_main__Order bynh_chk_set_main__Order bynh_chk_move_main__Order bynh_chk_ret_main__Order
true bynh_chk_claim_main__Order bynh_chk_set_main__Order bynh_chk_move_main__Order bynh_chk_ret_main__Order
true bynh_chk_claim_main__Order bynh_chk_set_main__Order bynh_chk_move_main__Order bynh_chk_ret_main__Order
true bynh_chk_claim_main__Order bynh_chk_set_main__Order bynh_chk_move_main__Order bynh_chk_ret_main__Order
false bynh_chk_claim_main__Money bynh_chk_set_main__Money bynh_chk_move_main__Money bynh_chk_ret_main__Money
false bynh_chk_claim_main__Money bynh_chk_set_main__Money bynh_chk_move_main__Money bynh_chk_ret_main__Money
false bynh_chk_claim_main__Money bynh_chk_set_main__Money bynh_chk_move_main__Money bynh_chk_ret_main__Money
false bynh_chk_claim_main__Money bynh_chk_set_main__Money bynh_chk_move_main__Money bynh_chk_ret_main__Money
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_main__Money bynh_chk_set_main__Money bynh_chk_move_main__Money bynh_chk_ret_main__Money
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_main__Money bynh_chk_set_main__Money bynh_chk_move_main__Money bynh_chk_ret_main__Money
true bynh_chk_claim_strbuf bynh_chk_set_strbuf bynh_chk_move_strbuf bynh_chk_ret_strbuf
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_main__Money bynh_chk_set_main__Money bynh_chk_move_main__Money bynh_chk_ret_main__Money
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_main__Line bynh_chk_set_main__Line bynh_chk_move_main__Line bynh_chk_ret_main__Line
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
helper bynh_chk_claim_main__Currency
static void bynh_chk_claim_main__Currency(byn_main_Currency* p, const char* file, int line) {
}
helper bynh_chk_set_main__Currency
static byn_main_Currency bynh_chk_set_main__Currency(byn_main_Currency* p, byn_main_Currency v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Currency(p, file, line);
    return v;
}
helper bynh_chk_move_main__Currency
static byn_main_Currency* bynh_chk_move_main__Currency(byn_main_Currency* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Currency", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Currency
static byn_main_Currency bynh_chk_ret_main__Currency(byn_main_Currency v) {
    return v;
}
helper bynh_chk_claim_str
static void bynh_chk_claim_str(byn_str* p, const char* file, int line) {
}
helper bynh_chk_set_str
static byn_str bynh_chk_set_str(byn_str* p, byn_str v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_str(p, file, line);
    return v;
}
helper bynh_chk_move_str
static byn_str* bynh_chk_move_str(byn_str* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "string", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_str
static byn_str bynh_chk_ret_str(byn_str v) {
    return v;
}
helper bynh_chk_claim_err
static void bynh_chk_claim_err(byn_err* p, const char* file, int line) {
}
helper bynh_chk_set_err
static byn_err bynh_chk_set_err(byn_err* p, byn_err v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_err(p, file, line);
    return v;
}
helper bynh_chk_move_err
static byn_err* bynh_chk_move_err(byn_err* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "OrderError", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_err
static byn_err bynh_chk_ret_err(byn_err v) {
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
helper bynh_chk_claim_main__Order
static void bynh_chk_claim_main__Order(bynt_main__Order* p, const char* file, int line) {
    byn_own_claim((*p).lines.ptr, &(*p).lines, "List<Line>", file, line);
}
helper bynh_chk_set_main__Order
static bynt_main__Order bynh_chk_set_main__Order(bynt_main__Order* p, bynt_main__Order v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).lines.ptr, &(*p).lines);
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Order(p, file, line);
    return v;
}
helper bynh_chk_move_main__Order
static bynt_main__Order* bynh_chk_move_main__Order(bynt_main__Order* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Order", file, line);
    byn_own_release((*p).lines.ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Order
static bynt_main__Order bynh_chk_ret_main__Order(bynt_main__Order v) {
    byn_own_release(v.lines.ptr);
    return v;
}
helper bynh_chk_claim_main__Money
static void bynh_chk_claim_main__Money(bynt_main__Money* p, const char* file, int line) {
}
helper bynh_chk_set_main__Money
static bynt_main__Money bynh_chk_set_main__Money(bynt_main__Money* p, bynt_main__Money v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Money(p, file, line);
    return v;
}
helper bynh_chk_move_main__Money
static bynt_main__Money* bynh_chk_move_main__Money(bynt_main__Money* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Money", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Money
static bynt_main__Money bynh_chk_ret_main__Money(bynt_main__Money v) {
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