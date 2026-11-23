false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_res_str bynh_chk_set_res_str bynh_chk_move_res_str bynh_chk_ret_res_str
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
helper bynh_chk_claim_res_str
static void bynh_chk_claim_res_str(bynt_res_str* p, const char* file, int line) {
}
helper bynh_chk_set_res_str
static bynt_res_str bynh_chk_set_res_str(bynt_res_str* p, bynt_res_str v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_res_str(p, file, line);
    return v;
}
helper bynh_chk_move_res_str
static bynt_res_str* bynh_chk_move_res_str(bynt_res_str* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Result<string, IoError>", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_res_str
static bynt_res_str bynh_chk_ret_res_str(bynt_res_str v) {
    return v;
}