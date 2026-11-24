false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_arr2_main__C bynh_chk_set_arr2_main__C bynh_chk_move_arr2_main__C bynh_chk_ret_arr2_main__C
true bynh_chk_claim_list_main__C bynh_chk_set_list_main__C bynh_chk_move_list_main__C bynh_chk_ret_list_main__C
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
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
helper bynh_chk_claim_arr2_main__C
static void bynh_chk_claim_arr2_main__C(bynt_arr2_main__C* p, const char* file, int line) {
}
helper bynh_chk_set_arr2_main__C
static bynt_arr2_main__C bynh_chk_set_arr2_main__C(bynt_arr2_main__C* p, bynt_arr2_main__C v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_arr2_main__C(p, file, line);
    return v;
}
helper bynh_chk_move_arr2_main__C
static bynt_arr2_main__C* bynh_chk_move_arr2_main__C(bynt_arr2_main__C* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "C[2]", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_arr2_main__C
static bynt_arr2_main__C bynh_chk_ret_arr2_main__C(bynt_arr2_main__C v) {
    return v;
}
helper bynh_chk_claim_list_main__C
static void bynh_chk_claim_list_main__C(bynt_list_main__C* p, const char* file, int line) {
    byn_own_claim((*p).ptr, &(*p), "List<C>", file, line);
}
helper bynh_chk_set_list_main__C
static bynt_list_main__C bynh_chk_set_list_main__C(bynt_list_main__C* p, bynt_list_main__C v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).ptr, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_list_main__C(p, file, line);
    return v;
}
helper bynh_chk_move_list_main__C
static bynt_list_main__C* bynh_chk_move_list_main__C(bynt_list_main__C* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "List<C>", file, line);
    byn_own_release((*p).ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_list_main__C
static bynt_list_main__C bynh_chk_ret_list_main__C(bynt_list_main__C v) {
    byn_own_release(v.ptr);
    return v;
}