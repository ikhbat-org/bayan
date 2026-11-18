false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_main__Point bynh_chk_set_main__Point bynh_chk_move_main__Point bynh_chk_ret_main__Point
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
helper bynh_chk_claim_main__Point
static void bynh_chk_claim_main__Point(bynt_main__Point* p, const char* file, int line) {
}
helper bynh_chk_set_main__Point
static bynt_main__Point bynh_chk_set_main__Point(bynt_main__Point* p, bynt_main__Point v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Point(p, file, line);
    return v;
}
helper bynh_chk_move_main__Point
static bynt_main__Point* bynh_chk_move_main__Point(bynt_main__Point* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Point", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Point
static bynt_main__Point bynh_chk_ret_main__Point(bynt_main__Point v) {
    return v;
}