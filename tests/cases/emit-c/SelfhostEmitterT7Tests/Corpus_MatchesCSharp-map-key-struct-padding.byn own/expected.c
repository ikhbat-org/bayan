false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_main__Pad bynh_chk_set_main__Pad bynh_chk_move_main__Pad bynh_chk_ret_main__Pad
false bynh_chk_claim_main__Pad bynh_chk_set_main__Pad bynh_chk_move_main__Pad bynh_chk_ret_main__Pad
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
true bynh_chk_claim_map_main__Pad_i32 bynh_chk_set_map_main__Pad_i32 bynh_chk_move_map_main__Pad_i32 bynh_chk_ret_map_main__Pad_i32
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
helper bynh_chk_claim_main__Pad
static void bynh_chk_claim_main__Pad(bynt_main__Pad* p, const char* file, int line) {
}
helper bynh_chk_set_main__Pad
static bynt_main__Pad bynh_chk_set_main__Pad(bynt_main__Pad* p, bynt_main__Pad v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Pad(p, file, line);
    return v;
}
helper bynh_chk_move_main__Pad
static bynt_main__Pad* bynh_chk_move_main__Pad(bynt_main__Pad* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Pad", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Pad
static bynt_main__Pad bynh_chk_ret_main__Pad(bynt_main__Pad v) {
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
helper bynh_chk_claim_map_main__Pad_i32
static void bynh_chk_claim_map_main__Pad_i32(bynt_map_main__Pad_i32* p, const char* file, int line) {
    byn_own_claim((*p).keys, &(*p), "Map<Pad, i32>", file, line);
}
helper bynh_chk_set_map_main__Pad_i32
static bynt_map_main__Pad_i32 bynh_chk_set_map_main__Pad_i32(bynt_map_main__Pad_i32* p, bynt_map_main__Pad_i32 v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).keys, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_map_main__Pad_i32(p, file, line);
    return v;
}
helper bynh_chk_move_map_main__Pad_i32
static bynt_map_main__Pad_i32* bynh_chk_move_map_main__Pad_i32(bynt_map_main__Pad_i32* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Map<Pad, i32>", file, line);
    byn_own_release((*p).keys);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_map_main__Pad_i32
static bynt_map_main__Pad_i32 bynh_chk_ret_map_main__Pad_i32(bynt_map_main__Pad_i32 v) {
    byn_own_release(v.keys);
    return v;
}