false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_fn1_i64_bool bynh_chk_set_fn1_i64_bool bynh_chk_move_fn1_i64_bool bynh_chk_ret_fn1_i64_bool
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_fn1_str_str bynh_chk_set_fn1_str_str bynh_chk_move_fn1_str_str bynh_chk_ret_fn1_str_str
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_fn1_str_void bynh_chk_set_fn1_str_void bynh_chk_move_fn1_str_void bynh_chk_ret_fn1_str_void
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_fn1_i64_bool bynh_chk_set_fn1_i64_bool bynh_chk_move_fn1_i64_bool bynh_chk_ret_fn1_i64_bool
false bynh_chk_claim_fn2_i64_i64_i64 bynh_chk_set_fn2_i64_i64_i64 bynh_chk_move_fn2_i64_i64_i64 bynh_chk_ret_fn2_i64_i64_i64
false bynh_chk_claim_fn1u1_str_alloc_str bynh_chk_set_fn1u1_str_alloc_str bynh_chk_move_fn1u1_str_alloc_str bynh_chk_ret_fn1u1_str_alloc_str
false bynh_chk_claim_fn1u1_str_console_void bynh_chk_set_fn1u1_str_console_void bynh_chk_move_fn1u1_str_console_void bynh_chk_ret_fn1u1_str_console_void
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
helper bynh_chk_claim_fn1_i64_bool
static void bynh_chk_claim_fn1_i64_bool(bynt_fn1_i64_bool* p, const char* file, int line) {
}
helper bynh_chk_set_fn1_i64_bool
static bynt_fn1_i64_bool bynh_chk_set_fn1_i64_bool(bynt_fn1_i64_bool* p, bynt_fn1_i64_bool v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_fn1_i64_bool(p, file, line);
    return v;
}
helper bynh_chk_move_fn1_i64_bool
static bynt_fn1_i64_bool* bynh_chk_move_fn1_i64_bool(bynt_fn1_i64_bool* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "i64 -> bool", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_fn1_i64_bool
static bynt_fn1_i64_bool bynh_chk_ret_fn1_i64_bool(bynt_fn1_i64_bool v) {
    return v;
}
helper bynh_chk_claim_fn1_str_str
static void bynh_chk_claim_fn1_str_str(bynt_fn1_str_str* p, const char* file, int line) {
}
helper bynh_chk_set_fn1_str_str
static bynt_fn1_str_str bynh_chk_set_fn1_str_str(bynt_fn1_str_str* p, bynt_fn1_str_str v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_fn1_str_str(p, file, line);
    return v;
}
helper bynh_chk_move_fn1_str_str
static bynt_fn1_str_str* bynh_chk_move_fn1_str_str(bynt_fn1_str_str* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "string -> string", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_fn1_str_str
static bynt_fn1_str_str bynh_chk_ret_fn1_str_str(bynt_fn1_str_str v) {
    return v;
}
helper bynh_chk_claim_fn1_str_void
static void bynh_chk_claim_fn1_str_void(bynt_fn1_str_void* p, const char* file, int line) {
}
helper bynh_chk_set_fn1_str_void
static bynt_fn1_str_void bynh_chk_set_fn1_str_void(bynt_fn1_str_void* p, bynt_fn1_str_void v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_fn1_str_void(p, file, line);
    return v;
}
helper bynh_chk_move_fn1_str_void
static bynt_fn1_str_void* bynh_chk_move_fn1_str_void(bynt_fn1_str_void* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "string -> void", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_fn1_str_void
static bynt_fn1_str_void bynh_chk_ret_fn1_str_void(bynt_fn1_str_void v) {
    return v;
}
helper bynh_chk_claim_fn2_i64_i64_i64
static void bynh_chk_claim_fn2_i64_i64_i64(bynt_fn2_i64_i64_i64* p, const char* file, int line) {
}
helper bynh_chk_set_fn2_i64_i64_i64
static bynt_fn2_i64_i64_i64 bynh_chk_set_fn2_i64_i64_i64(bynt_fn2_i64_i64_i64* p, bynt_fn2_i64_i64_i64 v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_fn2_i64_i64_i64(p, file, line);
    return v;
}
helper bynh_chk_move_fn2_i64_i64_i64
static bynt_fn2_i64_i64_i64* bynh_chk_move_fn2_i64_i64_i64(bynt_fn2_i64_i64_i64* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "(i64, i64) -> i64", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_fn2_i64_i64_i64
static bynt_fn2_i64_i64_i64 bynh_chk_ret_fn2_i64_i64_i64(bynt_fn2_i64_i64_i64 v) {
    return v;
}
helper bynh_chk_claim_fn1u1_str_alloc_str
static void bynh_chk_claim_fn1u1_str_alloc_str(bynt_fn1u1_str_alloc_str* p, const char* file, int line) {
}
helper bynh_chk_set_fn1u1_str_alloc_str
static bynt_fn1u1_str_alloc_str bynh_chk_set_fn1u1_str_alloc_str(bynt_fn1u1_str_alloc_str* p, bynt_fn1u1_str_alloc_str v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_fn1u1_str_alloc_str(p, file, line);
    return v;
}
helper bynh_chk_move_fn1u1_str_alloc_str
static bynt_fn1u1_str_alloc_str* bynh_chk_move_fn1u1_str_alloc_str(bynt_fn1u1_str_alloc_str* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "string -> string uses alloc", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_fn1u1_str_alloc_str
static bynt_fn1u1_str_alloc_str bynh_chk_ret_fn1u1_str_alloc_str(bynt_fn1u1_str_alloc_str v) {
    return v;
}
helper bynh_chk_claim_fn1u1_str_console_void
static void bynh_chk_claim_fn1u1_str_console_void(bynt_fn1u1_str_console_void* p, const char* file, int line) {
}
helper bynh_chk_set_fn1u1_str_console_void
static bynt_fn1u1_str_console_void bynh_chk_set_fn1u1_str_console_void(bynt_fn1u1_str_console_void* p, bynt_fn1u1_str_console_void v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_fn1u1_str_console_void(p, file, line);
    return v;
}
helper bynh_chk_move_fn1u1_str_console_void
static bynt_fn1u1_str_console_void* bynh_chk_move_fn1u1_str_console_void(bynt_fn1u1_str_console_void* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "string -> void uses console", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_fn1u1_str_console_void
static bynt_fn1u1_str_console_void bynh_chk_ret_fn1u1_str_console_void(bynt_fn1u1_str_console_void v) {
    return v;
}