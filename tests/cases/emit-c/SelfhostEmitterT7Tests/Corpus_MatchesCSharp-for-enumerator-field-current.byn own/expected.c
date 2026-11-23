false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_main__Ints bynh_chk_set_main__Ints bynh_chk_move_main__Ints bynh_chk_ret_main__Ints
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
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
helper bynh_chk_claim_main__Ints
static void bynh_chk_claim_main__Ints(bynt_main__Ints* p, const char* file, int line) {
}
helper bynh_chk_set_main__Ints
static bynt_main__Ints bynh_chk_set_main__Ints(bynt_main__Ints* p, bynt_main__Ints v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Ints(p, file, line);
    return v;
}
helper bynh_chk_move_main__Ints
static bynt_main__Ints* bynh_chk_move_main__Ints(bynt_main__Ints* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Ints", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Ints
static bynt_main__Ints bynh_chk_ret_main__Ints(bynt_main__Ints v) {
    return v;
}
helper bynh_chk_claim_bool
static void bynh_chk_claim_bool(bool* p, const char* file, int line) {
}
helper bynh_chk_set_bool
static bool bynh_chk_set_bool(bool* p, bool v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_bool(p, file, line);
    return v;
}
helper bynh_chk_move_bool
static bool* bynh_chk_move_bool(bool* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "bool", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_bool
static bool bynh_chk_ret_bool(bool v) {
    return v;
}