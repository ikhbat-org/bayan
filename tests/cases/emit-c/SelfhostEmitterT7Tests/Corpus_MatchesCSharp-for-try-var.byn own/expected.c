false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_main__Rows bynh_chk_set_main__Rows bynh_chk_move_main__Rows bynh_chk_ret_main__Rows
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_opt_i64 bynh_chk_set_opt_i64 bynh_chk_move_opt_i64 bynh_chk_ret_opt_i64
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
helper bynh_chk_claim_main__Rows
static void bynh_chk_claim_main__Rows(bynt_main__Rows* p, const char* file, int line) {
}
helper bynh_chk_set_main__Rows
static bynt_main__Rows bynh_chk_set_main__Rows(bynt_main__Rows* p, bynt_main__Rows v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Rows(p, file, line);
    return v;
}
helper bynh_chk_move_main__Rows
static bynt_main__Rows* bynh_chk_move_main__Rows(bynt_main__Rows* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Rows", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Rows
static bynt_main__Rows bynh_chk_ret_main__Rows(bynt_main__Rows v) {
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