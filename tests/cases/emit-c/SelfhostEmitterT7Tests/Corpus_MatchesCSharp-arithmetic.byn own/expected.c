false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_u8 bynh_chk_set_u8 bynh_chk_move_u8 bynh_chk_ret_u8
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_f64 bynh_chk_set_f64 bynh_chk_move_f64 bynh_chk_ret_f64
false bynh_chk_claim_f32 bynh_chk_set_f32 bynh_chk_move_f32 bynh_chk_ret_f32
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_rune bynh_chk_set_rune bynh_chk_move_rune bynh_chk_ret_rune
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_u64 bynh_chk_set_u64 bynh_chk_move_u64 bynh_chk_ret_u64
false bynh_chk_claim_f64 bynh_chk_set_f64 bynh_chk_move_f64 bynh_chk_ret_f64
false bynh_chk_claim_f64 bynh_chk_set_f64 bynh_chk_move_f64 bynh_chk_ret_f64
false bynh_chk_claim_f64 bynh_chk_set_f64 bynh_chk_move_f64 bynh_chk_ret_f64
false bynh_chk_claim_f64 bynh_chk_set_f64 bynh_chk_move_f64 bynh_chk_ret_f64
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
helper bynh_chk_claim_u8
static void bynh_chk_claim_u8(uint8_t* p, const char* file, int line) {
}
helper bynh_chk_set_u8
static uint8_t bynh_chk_set_u8(uint8_t* p, uint8_t v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_u8(p, file, line);
    return v;
}
helper bynh_chk_move_u8
static uint8_t* bynh_chk_move_u8(uint8_t* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "u8", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_u8
static uint8_t bynh_chk_ret_u8(uint8_t v) {
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
helper bynh_chk_claim_f64
static void bynh_chk_claim_f64(double* p, const char* file, int line) {
}
helper bynh_chk_set_f64
static double bynh_chk_set_f64(double* p, double v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_f64(p, file, line);
    return v;
}
helper bynh_chk_move_f64
static double* bynh_chk_move_f64(double* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "f64", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_f64
static double bynh_chk_ret_f64(double v) {
    return v;
}
helper bynh_chk_claim_f32
static void bynh_chk_claim_f32(float* p, const char* file, int line) {
}
helper bynh_chk_set_f32
static float bynh_chk_set_f32(float* p, float v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_f32(p, file, line);
    return v;
}
helper bynh_chk_move_f32
static float* bynh_chk_move_f32(float* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "f32", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_f32
static float bynh_chk_ret_f32(float v) {
    return v;
}
helper bynh_chk_claim_rune
static void bynh_chk_claim_rune(uint32_t* p, const char* file, int line) {
}
helper bynh_chk_set_rune
static uint32_t bynh_chk_set_rune(uint32_t* p, uint32_t v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_rune(p, file, line);
    return v;
}
helper bynh_chk_move_rune
static uint32_t* bynh_chk_move_rune(uint32_t* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "rune", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_rune
static uint32_t bynh_chk_ret_rune(uint32_t v) {
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