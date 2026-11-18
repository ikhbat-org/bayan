false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_i8 bynh_chk_set_i8 bynh_chk_move_i8 bynh_chk_ret_i8
false bynh_chk_claim_i8 bynh_chk_set_i8 bynh_chk_move_i8 bynh_chk_ret_i8
false bynh_chk_claim_i8 bynh_chk_set_i8 bynh_chk_move_i8 bynh_chk_ret_i8
false bynh_chk_claim_i16 bynh_chk_set_i16 bynh_chk_move_i16 bynh_chk_ret_i16
false bynh_chk_claim_i16 bynh_chk_set_i16 bynh_chk_move_i16 bynh_chk_ret_i16
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_isize bynh_chk_set_isize bynh_chk_move_isize bynh_chk_ret_isize
false bynh_chk_claim_u8 bynh_chk_set_u8 bynh_chk_move_u8 bynh_chk_ret_u8
false bynh_chk_claim_u8 bynh_chk_set_u8 bynh_chk_move_u8 bynh_chk_ret_u8
false bynh_chk_claim_u16 bynh_chk_set_u16 bynh_chk_move_u16 bynh_chk_ret_u16
false bynh_chk_claim_u32 bynh_chk_set_u32 bynh_chk_move_u32 bynh_chk_ret_u32
false bynh_chk_claim_u64 bynh_chk_set_u64 bynh_chk_move_u64 bynh_chk_ret_u64
false bynh_chk_claim_usize bynh_chk_set_usize bynh_chk_move_usize bynh_chk_ret_usize
false bynh_chk_claim_arena bynh_chk_set_arena bynh_chk_move_arena bynh_chk_ret_arena
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
helper bynh_chk_claim_i16
static void bynh_chk_claim_i16(int16_t* p, const char* file, int line) {
}
helper bynh_chk_set_i16
static int16_t bynh_chk_set_i16(int16_t* p, int16_t v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_i16(p, file, line);
    return v;
}
helper bynh_chk_move_i16
static int16_t* bynh_chk_move_i16(int16_t* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "i16", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_i16
static int16_t bynh_chk_ret_i16(int16_t v) {
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
helper bynh_chk_claim_isize
static void bynh_chk_claim_isize(int64_t* p, const char* file, int line) {
}
helper bynh_chk_set_isize
static int64_t bynh_chk_set_isize(int64_t* p, int64_t v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_isize(p, file, line);
    return v;
}
helper bynh_chk_move_isize
static int64_t* bynh_chk_move_isize(int64_t* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "isize", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_isize
static int64_t bynh_chk_ret_isize(int64_t v) {
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
helper bynh_chk_claim_u16
static void bynh_chk_claim_u16(uint16_t* p, const char* file, int line) {
}
helper bynh_chk_set_u16
static uint16_t bynh_chk_set_u16(uint16_t* p, uint16_t v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_u16(p, file, line);
    return v;
}
helper bynh_chk_move_u16
static uint16_t* bynh_chk_move_u16(uint16_t* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "u16", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_u16
static uint16_t bynh_chk_ret_u16(uint16_t v) {
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
helper bynh_chk_claim_usize
static void bynh_chk_claim_usize(uint64_t* p, const char* file, int line) {
}
helper bynh_chk_set_usize
static uint64_t bynh_chk_set_usize(uint64_t* p, uint64_t v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_usize(p, file, line);
    return v;
}
helper bynh_chk_move_usize
static uint64_t* bynh_chk_move_usize(uint64_t* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "usize", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_usize
static uint64_t bynh_chk_ret_usize(uint64_t v) {
    return v;
}
helper bynh_chk_claim_arena
static void bynh_chk_claim_arena(byn_arena** p, const char* file, int line) {
}
helper bynh_chk_set_arena
static byn_arena* bynh_chk_set_arena(byn_arena** p, byn_arena* v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_arena(p, file, line);
    return v;
}
helper bynh_chk_move_arena
static byn_arena** bynh_chk_move_arena(byn_arena** p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Arena", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_arena
static byn_arena* bynh_chk_ret_arena(byn_arena* v) {
    return v;
}