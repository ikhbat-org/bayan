false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
true bynh_chk_claim_list_i64 bynh_chk_set_list_i64 bynh_chk_move_list_i64 bynh_chk_ret_list_i64
true bynh_chk_claim_map_str_i64 bynh_chk_set_map_str_i64 bynh_chk_move_map_str_i64 bynh_chk_ret_map_str_i64
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
true bynh_chk_claim_list_list_i64 bynh_chk_set_list_list_i64 bynh_chk_move_list_list_i64 bynh_chk_ret_list_list_i64
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
helper bynh_chk_claim_list_i64
static void bynh_chk_claim_list_i64(bynt_list_i64* p, const char* file, int line) {
    byn_own_claim((*p).ptr, &(*p), "List<i64>", file, line);
}
helper bynh_chk_set_list_i64
static bynt_list_i64 bynh_chk_set_list_i64(bynt_list_i64* p, bynt_list_i64 v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).ptr, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_list_i64(p, file, line);
    return v;
}
helper bynh_chk_move_list_i64
static bynt_list_i64* bynh_chk_move_list_i64(bynt_list_i64* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "List<i64>", file, line);
    byn_own_release((*p).ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_list_i64
static bynt_list_i64 bynh_chk_ret_list_i64(bynt_list_i64 v) {
    byn_own_release(v.ptr);
    return v;
}
helper bynh_chk_claim_map_str_i64
static void bynh_chk_claim_map_str_i64(bynt_map_str_i64* p, const char* file, int line) {
    byn_own_claim((*p).keys, &(*p), "Map<string, i64>", file, line);
}
helper bynh_chk_set_map_str_i64
static bynt_map_str_i64 bynh_chk_set_map_str_i64(bynt_map_str_i64* p, bynt_map_str_i64 v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).keys, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_map_str_i64(p, file, line);
    return v;
}
helper bynh_chk_move_map_str_i64
static bynt_map_str_i64* bynh_chk_move_map_str_i64(bynt_map_str_i64* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Map<string, i64>", file, line);
    byn_own_release((*p).keys);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_map_str_i64
static bynt_map_str_i64 bynh_chk_ret_map_str_i64(bynt_map_str_i64 v) {
    byn_own_release(v.keys);
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
helper bynh_chk_claim_list_list_i64
static void bynh_chk_claim_list_list_i64(bynt_list_list_i64* p, const char* file, int line) {
    byn_own_claim((*p).ptr, &(*p), "List<List<i64>>", file, line);
}
helper bynh_chk_set_list_list_i64
static bynt_list_list_i64 bynh_chk_set_list_list_i64(bynt_list_list_i64* p, bynt_list_list_i64 v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).ptr, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_list_list_i64(p, file, line);
    return v;
}
helper bynh_chk_move_list_list_i64
static bynt_list_list_i64* bynh_chk_move_list_list_i64(bynt_list_list_i64* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "List<List<i64>>", file, line);
    byn_own_release((*p).ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_list_list_i64
static bynt_list_list_i64 bynh_chk_ret_list_list_i64(bynt_list_list_i64 v) {
    byn_own_release(v.ptr);
    return v;
}