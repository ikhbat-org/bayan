false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_err bynh_chk_set_err bynh_chk_move_err bynh_chk_ret_err
false bynh_chk_claim_err bynh_chk_set_err bynh_chk_move_err bynh_chk_ret_err
false bynh_chk_claim_err bynh_chk_set_err bynh_chk_move_err bynh_chk_ret_err
false bynh_chk_claim_err bynh_chk_set_err bynh_chk_move_err bynh_chk_ret_err
false bynh_chk_claim_err bynh_chk_set_err bynh_chk_move_err bynh_chk_ret_err
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
helper bynh_chk_claim_err
static void bynh_chk_claim_err(byn_err* p, const char* file, int line) {
}
helper bynh_chk_set_err
static byn_err bynh_chk_set_err(byn_err* p, byn_err v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_err(p, file, line);
    return v;
}
helper bynh_chk_move_err
static byn_err* bynh_chk_move_err(byn_err* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "ParseError", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_err
static byn_err bynh_chk_ret_err(byn_err v) {
    return v;
}