false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_arr2_str bynh_chk_set_arr2_str bynh_chk_move_arr2_str bynh_chk_ret_arr2_str
false bynh_chk_claim_process bynh_chk_set_process bynh_chk_move_process bynh_chk_ret_process
false bynh_chk_claim_arr1_str bynh_chk_set_arr1_str bynh_chk_move_arr1_str bynh_chk_ret_arr1_str
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
helper bynh_chk_claim_process
static void bynh_chk_claim_process(byn_process* p, const char* file, int line) {
}
helper bynh_chk_set_process
static byn_process bynh_chk_set_process(byn_process* p, byn_process v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_process(p, file, line);
    return v;
}
helper bynh_chk_move_process
static byn_process* bynh_chk_move_process(byn_process* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "ProcessResult", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_process
static byn_process bynh_chk_ret_process(byn_process v) {
    return v;
}
helper bynh_chk_claim_arr1_str
static void bynh_chk_claim_arr1_str(bynt_arr1_str* p, const char* file, int line) {
}
helper bynh_chk_set_arr1_str
static bynt_arr1_str bynh_chk_set_arr1_str(bynt_arr1_str* p, bynt_arr1_str v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_arr1_str(p, file, line);
    return v;
}
helper bynh_chk_move_arr1_str
static bynt_arr1_str* bynh_chk_move_arr1_str(bynt_arr1_str* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "string[1]", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_arr1_str
static bynt_arr1_str bynh_chk_ret_arr1_str(bynt_arr1_str v) {
    return v;
}