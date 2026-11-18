false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_millis bynh_chk_set_millis bynh_chk_move_millis bynh_chk_ret_millis
false bynh_chk_claim_millis bynh_chk_set_millis bynh_chk_move_millis bynh_chk_ret_millis
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
helper bynh_chk_claim_millis
static void bynh_chk_claim_millis(int64_t* p, const char* file, int line) {
}
helper bynh_chk_set_millis
static int64_t bynh_chk_set_millis(int64_t* p, int64_t v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_millis(p, file, line);
    return v;
}
helper bynh_chk_move_millis
static int64_t* bynh_chk_move_millis(int64_t* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Millis", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_millis
static int64_t bynh_chk_ret_millis(int64_t v) {
    return v;
}