false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_i8 bynh_chk_set_i8 bynh_chk_move_i8 bynh_chk_ret_i8
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_u64 bynh_chk_set_u64 bynh_chk_move_u64 bynh_chk_ret_u64
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
helper bynh_chk_claim_i8
static void bynh_chk_claim_i8(int8_t* p, const char* file, int line) {
}
helper bynh_chk_set_i8
static int8_t bynh_chk_set_i8(int8_t* p, int8_t v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_i8(p, file, line);
    return v;
}
helper bynh_chk_move_i8
static int8_t* bynh_chk_move_i8(int8_t* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "i8", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_i8
static int8_t bynh_chk_ret_i8(int8_t v) {
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