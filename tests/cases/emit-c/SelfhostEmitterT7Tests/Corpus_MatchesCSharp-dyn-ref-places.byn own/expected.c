false bynh_chk_claim_dyn_main__ICounter bynh_chk_set_dyn_main__ICounter bynh_chk_move_dyn_main__ICounter bynh_chk_ret_dyn_main__ICounter
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_dyn_main__ICounter bynh_chk_set_dyn_main__ICounter bynh_chk_move_dyn_main__ICounter bynh_chk_ret_dyn_main__ICounter
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_main__Counter bynh_chk_set_main__Counter bynh_chk_move_main__Counter bynh_chk_ret_main__Counter
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_main__Pair bynh_chk_set_main__Pair bynh_chk_move_main__Pair bynh_chk_ret_main__Pair
false bynh_chk_claim_dyn_main__ICounter bynh_chk_set_dyn_main__ICounter bynh_chk_move_dyn_main__ICounter bynh_chk_ret_dyn_main__ICounter
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_main__Counter bynh_chk_set_main__Counter bynh_chk_move_main__Counter bynh_chk_ret_main__Counter
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_main__Pair bynh_chk_set_main__Pair bynh_chk_move_main__Pair bynh_chk_ret_main__Pair
false bynh_chk_claim_dyn_main__ICounter bynh_chk_set_dyn_main__ICounter bynh_chk_move_dyn_main__ICounter bynh_chk_ret_dyn_main__ICounter
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
helper bynh_chk_claim_dyn_main__ICounter
static void bynh_chk_claim_dyn_main__ICounter(byn_dyn_main__ICounter* p, const char* file, int line) {
}
helper bynh_chk_set_dyn_main__ICounter
static byn_dyn_main__ICounter bynh_chk_set_dyn_main__ICounter(byn_dyn_main__ICounter* p, byn_dyn_main__ICounter v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_dyn_main__ICounter(p, file, line);
    return v;
}
helper bynh_chk_move_dyn_main__ICounter
static byn_dyn_main__ICounter* bynh_chk_move_dyn_main__ICounter(byn_dyn_main__ICounter* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "dyn ref ICounter", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_dyn_main__ICounter
static byn_dyn_main__ICounter bynh_chk_ret_dyn_main__ICounter(byn_dyn_main__ICounter v) {
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
helper bynh_chk_claim_main__Counter
static void bynh_chk_claim_main__Counter(bynt_main__Counter* p, const char* file, int line) {
}
helper bynh_chk_set_main__Counter
static bynt_main__Counter bynh_chk_set_main__Counter(bynt_main__Counter* p, bynt_main__Counter v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Counter(p, file, line);
    return v;
}
helper bynh_chk_move_main__Counter
static bynt_main__Counter* bynh_chk_move_main__Counter(bynt_main__Counter* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Counter", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Counter
static bynt_main__Counter bynh_chk_ret_main__Counter(bynt_main__Counter v) {
    return v;
}
helper bynh_chk_claim_main__Pair
static void bynh_chk_claim_main__Pair(bynt_main__Pair* p, const char* file, int line) {
}
helper bynh_chk_set_main__Pair
static bynt_main__Pair bynh_chk_set_main__Pair(bynt_main__Pair* p, bynt_main__Pair v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Pair(p, file, line);
    return v;
}
helper bynh_chk_move_main__Pair
static bynt_main__Pair* bynh_chk_move_main__Pair(bynt_main__Pair* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Pair", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Pair
static bynt_main__Pair bynh_chk_ret_main__Pair(bynt_main__Pair v) {
    return v;
}