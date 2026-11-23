false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_rune bynh_chk_set_rune bynh_chk_move_rune bynh_chk_ret_rune
false bynh_chk_claim_rune bynh_chk_set_rune bynh_chk_move_rune bynh_chk_ret_rune
false bynh_chk_claim_rune bynh_chk_set_rune bynh_chk_move_rune bynh_chk_ret_rune
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
helper bynh_chk_claim_rune
static void bynh_chk_claim_rune(uint32_t* p, const char* file, int line) {
}
helper bynh_chk_set_rune
static uint32_t bynh_chk_set_rune(uint32_t* p, uint32_t v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_rune(p, file, line);
    return v;
}
helper bynh_chk_move_rune
static uint32_t* bynh_chk_move_rune(uint32_t* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "rune", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_rune
static uint32_t bynh_chk_ret_rune(uint32_t v) {
    return v;
}