false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_main__Money bynh_chk_set_main__Money bynh_chk_move_main__Money bynh_chk_ret_main__Money
false bynh_chk_claim_main__Color bynh_chk_set_main__Color bynh_chk_move_main__Color bynh_chk_ret_main__Color
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
helper bynh_chk_claim_main__Money
static void bynh_chk_claim_main__Money(bynt_main__Money* p, const char* file, int line) {
}
helper bynh_chk_set_main__Money
static bynt_main__Money bynh_chk_set_main__Money(bynt_main__Money* p, bynt_main__Money v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Money(p, file, line);
    return v;
}
helper bynh_chk_move_main__Money
static bynt_main__Money* bynh_chk_move_main__Money(bynt_main__Money* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Money", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Money
static bynt_main__Money bynh_chk_ret_main__Money(bynt_main__Money v) {
    return v;
}
helper bynh_chk_claim_main__Color
static void bynh_chk_claim_main__Color(byn_main_Color* p, const char* file, int line) {
}
helper bynh_chk_set_main__Color
static byn_main_Color bynh_chk_set_main__Color(byn_main_Color* p, byn_main_Color v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Color(p, file, line);
    return v;
}
helper bynh_chk_move_main__Color
static byn_main_Color* bynh_chk_move_main__Color(byn_main_Color* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Color", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Color
static byn_main_Color bynh_chk_ret_main__Color(byn_main_Color v) {
    return v;
}