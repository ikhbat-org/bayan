true bynh_chk_claim_list_main__S bynh_chk_set_list_main__S bynh_chk_move_list_main__S bynh_chk_ret_list_main__S
true bynh_chk_claim_list_main__S bynh_chk_set_list_main__S bynh_chk_move_list_main__S bynh_chk_ret_list_main__S
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
helper bynh_chk_claim_list_main__S
static void bynh_chk_claim_list_main__S(bynt_list_main__S* p, const char* file, int line) {
    byn_own_claim((*p).ptr, &(*p), "List<S>", file, line);
}
helper bynh_chk_set_list_main__S
static bynt_list_main__S bynh_chk_set_list_main__S(bynt_list_main__S* p, bynt_list_main__S v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).ptr, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_list_main__S(p, file, line);
    return v;
}
helper bynh_chk_move_list_main__S
static bynt_list_main__S* bynh_chk_move_list_main__S(bynt_list_main__S* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "List<S>", file, line);
    byn_own_release((*p).ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_list_main__S
static bynt_list_main__S bynh_chk_ret_list_main__S(bynt_list_main__S v) {
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