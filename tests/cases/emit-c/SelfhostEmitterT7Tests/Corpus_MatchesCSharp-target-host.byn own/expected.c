false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_arr3_str bynh_chk_set_arr3_str bynh_chk_move_arr3_str bynh_chk_ret_arr3_str
false bynh_chk_claim_arr2_str bynh_chk_set_arr2_str bynh_chk_move_arr2_str bynh_chk_ret_arr2_str
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
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
helper bynh_chk_claim_arr3_str
static void bynh_chk_claim_arr3_str(bynt_arr3_str* p, const char* file, int line) {
}
helper bynh_chk_set_arr3_str
static bynt_arr3_str bynh_chk_set_arr3_str(bynt_arr3_str* p, bynt_arr3_str v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_arr3_str(p, file, line);
    return v;
}
helper bynh_chk_move_arr3_str
static bynt_arr3_str* bynh_chk_move_arr3_str(bynt_arr3_str* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "string[3]", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_arr3_str
static bynt_arr3_str bynh_chk_ret_arr3_str(bynt_arr3_str v) {
    return v;
}
helper bynh_chk_claim_arr2_str
static void bynh_chk_claim_arr2_str(bynt_arr2_str* p, const char* file, int line) {
}
helper bynh_chk_set_arr2_str
static bynt_arr2_str bynh_chk_set_arr2_str(bynt_arr2_str* p, bynt_arr2_str v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_arr2_str(p, file, line);
    return v;
}
helper bynh_chk_move_arr2_str
static bynt_arr2_str* bynh_chk_move_arr2_str(bynt_arr2_str* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "string[2]", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_arr2_str
static bynt_arr2_str bynh_chk_ret_arr2_str(bynt_arr2_str v) {
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