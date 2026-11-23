false bynh_chk_claim_span_u32 bynh_chk_set_span_u32 bynh_chk_move_span_u32 bynh_chk_ret_span_u32
false bynh_chk_claim_u32 bynh_chk_set_u32 bynh_chk_move_u32 bynh_chk_ret_u32
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_span_u32 bynh_chk_set_span_u32 bynh_chk_move_span_u32 bynh_chk_ret_span_u32
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_arr6_u32 bynh_chk_set_arr6_u32 bynh_chk_move_arr6_u32 bynh_chk_ret_arr6_u32
false bynh_chk_claim_span_u32 bynh_chk_set_span_u32 bynh_chk_move_span_u32 bynh_chk_ret_span_u32
false bynh_chk_claim_u64 bynh_chk_set_u64 bynh_chk_move_u64 bynh_chk_ret_u64
helper bynh_chk_claim_span_u32
static void bynh_chk_claim_span_u32(bynt_span_u32* p, const char* file, int line) {
}
helper bynh_chk_set_span_u32
static bynt_span_u32 bynh_chk_set_span_u32(bynt_span_u32* p, bynt_span_u32 v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_span_u32(p, file, line);
    return v;
}
helper bynh_chk_move_span_u32
static bynt_span_u32* bynh_chk_move_span_u32(bynt_span_u32* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "ReadOnlySpan<u32>", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_span_u32
static bynt_span_u32 bynh_chk_ret_span_u32(bynt_span_u32 v) {
    return v;
}
helper bynh_chk_claim_u32
static void bynh_chk_claim_u32(uint32_t* p, const char* file, int line) {
}
helper bynh_chk_set_u32
static uint32_t bynh_chk_set_u32(uint32_t* p, uint32_t v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_u32(p, file, line);
    return v;
}
helper bynh_chk_move_u32
static uint32_t* bynh_chk_move_u32(uint32_t* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "u32", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_u32
static uint32_t bynh_chk_ret_u32(uint32_t v) {
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
helper bynh_chk_claim_arr6_u32
static void bynh_chk_claim_arr6_u32(bynt_arr6_u32* p, const char* file, int line) {
}
helper bynh_chk_set_arr6_u32
static bynt_arr6_u32 bynh_chk_set_arr6_u32(bynt_arr6_u32* p, bynt_arr6_u32 v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_arr6_u32(p, file, line);
    return v;
}
helper bynh_chk_move_arr6_u32
static bynt_arr6_u32* bynh_chk_move_arr6_u32(bynt_arr6_u32* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "u32[6]", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_arr6_u32
static bynt_arr6_u32 bynh_chk_ret_arr6_u32(bynt_arr6_u32 v) {
    return v;
}
helper bynh_chk_claim_u64
static void bynh_chk_claim_u64(uint64_t* p, const char* file, int line) {
}
helper bynh_chk_set_u64
static uint64_t bynh_chk_set_u64(uint64_t* p, uint64_t v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_u64(p, file, line);
    return v;
}
helper bynh_chk_move_u64
static uint64_t* bynh_chk_move_u64(uint64_t* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "u64", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_u64
static uint64_t bynh_chk_ret_u64(uint64_t v) {
    return v;
}