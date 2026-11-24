false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
true bynh_chk_claim_list_u8 bynh_chk_set_list_u8 bynh_chk_move_list_u8 bynh_chk_ret_list_u8
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_arr2_u8 bynh_chk_set_arr2_u8 bynh_chk_move_arr2_u8 bynh_chk_ret_arr2_u8
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_arr9_u8 bynh_chk_set_arr9_u8 bynh_chk_move_arr9_u8 bynh_chk_ret_arr9_u8
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_opt_i64 bynh_chk_set_opt_i64 bynh_chk_move_opt_i64 bynh_chk_ret_opt_i64
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
helper bynh_chk_claim_list_u8
static void bynh_chk_claim_list_u8(bynt_list_u8* p, const char* file, int line) {
    byn_own_claim((*p).ptr, &(*p), "List<u8>", file, line);
}
helper bynh_chk_set_list_u8
static bynt_list_u8 bynh_chk_set_list_u8(bynt_list_u8* p, bynt_list_u8 v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).ptr, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_list_u8(p, file, line);
    return v;
}
helper bynh_chk_move_list_u8
static bynt_list_u8* bynh_chk_move_list_u8(bynt_list_u8* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "List<u8>", file, line);
    byn_own_release((*p).ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_list_u8
static bynt_list_u8 bynh_chk_ret_list_u8(bynt_list_u8 v) {
    byn_own_release(v.ptr);
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
helper bynh_chk_claim_arr2_u8
static void bynh_chk_claim_arr2_u8(bynt_arr2_u8* p, const char* file, int line) {
}
helper bynh_chk_set_arr2_u8
static bynt_arr2_u8 bynh_chk_set_arr2_u8(bynt_arr2_u8* p, bynt_arr2_u8 v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_arr2_u8(p, file, line);
    return v;
}
helper bynh_chk_move_arr2_u8
static bynt_arr2_u8* bynh_chk_move_arr2_u8(bynt_arr2_u8* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "u8[2]", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_arr2_u8
static bynt_arr2_u8 bynh_chk_ret_arr2_u8(bynt_arr2_u8 v) {
    return v;
}
helper bynh_chk_claim_arr9_u8
static void bynh_chk_claim_arr9_u8(bynt_arr9_u8* p, const char* file, int line) {
}
helper bynh_chk_set_arr9_u8
static bynt_arr9_u8 bynh_chk_set_arr9_u8(bynt_arr9_u8* p, bynt_arr9_u8 v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_arr9_u8(p, file, line);
    return v;
}
helper bynh_chk_move_arr9_u8
static bynt_arr9_u8* bynh_chk_move_arr9_u8(bynt_arr9_u8* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "u8[9]", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_arr9_u8
static bynt_arr9_u8 bynh_chk_ret_arr9_u8(bynt_arr9_u8 v) {
    return v;
}
helper bynh_chk_claim_opt_i64
static void bynh_chk_claim_opt_i64(bynt_opt_i64* p, const char* file, int line) {
}
helper bynh_chk_set_opt_i64
static bynt_opt_i64 bynh_chk_set_opt_i64(bynt_opt_i64* p, bynt_opt_i64 v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_opt_i64(p, file, line);
    return v;
}
helper bynh_chk_move_opt_i64
static bynt_opt_i64* bynh_chk_move_opt_i64(bynt_opt_i64* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "i64\077", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_opt_i64
static bynt_opt_i64 bynh_chk_ret_opt_i64(bynt_opt_i64 v) {
    return v;
}