false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_arr12_tup2_str_str bynh_chk_set_arr12_tup2_str_str bynh_chk_move_arr12_tup2_str_str bynh_chk_ret_arr12_tup2_str_str
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
helper bynh_chk_claim_arr12_tup2_str_str
static void bynh_chk_claim_arr12_tup2_str_str(bynt_arr12_tup2_str_str* p, const char* file, int line) {
}
helper bynh_chk_set_arr12_tup2_str_str
static bynt_arr12_tup2_str_str bynh_chk_set_arr12_tup2_str_str(bynt_arr12_tup2_str_str* p, bynt_arr12_tup2_str_str v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_arr12_tup2_str_str(p, file, line);
    return v;
}
helper bynh_chk_move_arr12_tup2_str_str
static bynt_arr12_tup2_str_str* bynh_chk_move_arr12_tup2_str_str(bynt_arr12_tup2_str_str* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "(string, string)[12]", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_arr12_tup2_str_str
static bynt_arr12_tup2_str_str bynh_chk_ret_arr12_tup2_str_str(bynt_arr12_tup2_str_str v) {
    return v;
}