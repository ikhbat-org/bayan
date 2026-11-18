false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_main__Stat bynh_chk_set_main__Stat bynh_chk_move_main__Stat bynh_chk_ret_main__Stat
true bynh_chk_claim_list_main__Stat bynh_chk_set_list_main__Stat bynh_chk_move_list_main__Stat bynh_chk_ret_list_main__Stat
true bynh_chk_claim_map_str_main__Stat bynh_chk_set_map_str_main__Stat bynh_chk_move_map_str_main__Stat bynh_chk_ret_map_str_main__Stat
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
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
helper bynh_chk_claim_main__Stat
static void bynh_chk_claim_main__Stat(bynt_main__Stat* p, const char* file, int line) {
}
helper bynh_chk_set_main__Stat
static bynt_main__Stat bynh_chk_set_main__Stat(bynt_main__Stat* p, bynt_main__Stat v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Stat(p, file, line);
    return v;
}
helper bynh_chk_move_main__Stat
static bynt_main__Stat* bynh_chk_move_main__Stat(bynt_main__Stat* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Stat", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Stat
static bynt_main__Stat bynh_chk_ret_main__Stat(bynt_main__Stat v) {
    return v;
}
helper bynh_chk_claim_list_main__Stat
static void bynh_chk_claim_list_main__Stat(bynt_list_main__Stat* p, const char* file, int line) {
    byn_own_claim((*p).ptr, &(*p), "List<Stat>", file, line);
}
helper bynh_chk_set_list_main__Stat
static bynt_list_main__Stat bynh_chk_set_list_main__Stat(bynt_list_main__Stat* p, bynt_list_main__Stat v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).ptr, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_list_main__Stat(p, file, line);
    return v;
}
helper bynh_chk_move_list_main__Stat
static bynt_list_main__Stat* bynh_chk_move_list_main__Stat(bynt_list_main__Stat* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "List<Stat>", file, line);
    byn_own_release((*p).ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_list_main__Stat
static bynt_list_main__Stat bynh_chk_ret_list_main__Stat(bynt_list_main__Stat v) {
    byn_own_release(v.ptr);
    return v;
}
helper bynh_chk_claim_map_str_main__Stat
static void bynh_chk_claim_map_str_main__Stat(bynt_map_str_main__Stat* p, const char* file, int line) {
    byn_own_claim((*p).keys, &(*p), "Map<string, Stat>", file, line);
}
helper bynh_chk_set_map_str_main__Stat
static bynt_map_str_main__Stat bynh_chk_set_map_str_main__Stat(bynt_map_str_main__Stat* p, bynt_map_str_main__Stat v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).keys, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_map_str_main__Stat(p, file, line);
    return v;
}
helper bynh_chk_move_map_str_main__Stat
static bynt_map_str_main__Stat* bynh_chk_move_map_str_main__Stat(bynt_map_str_main__Stat* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Map<string, Stat>", file, line);
    byn_own_release((*p).keys);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_map_str_main__Stat
static bynt_map_str_main__Stat bynh_chk_ret_map_str_main__Stat(bynt_map_str_main__Stat v) {
    byn_own_release(v.keys);
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