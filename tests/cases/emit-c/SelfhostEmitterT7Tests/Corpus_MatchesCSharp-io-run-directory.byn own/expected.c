false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_arr2_str bynh_chk_set_arr2_str bynh_chk_move_arr2_str bynh_chk_ret_arr2_str
false bynh_chk_claim_process bynh_chk_set_process bynh_chk_move_process bynh_chk_ret_process
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_arr2_u8 bynh_chk_set_arr2_u8 bynh_chk_move_arr2_u8 bynh_chk_ret_arr2_u8
false bynh_chk_claim_arr2_str bynh_chk_set_arr2_str bynh_chk_move_arr2_str bynh_chk_ret_arr2_str
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
helper bynh_chk_claim_arr2_u8
static void bynh_chk_claim_arr2_u8(bynt_arr2_u8* p, const char* file, int line) {
}
helper bynh_chk_set_arr2_u8
static bynt_arr2_u8 bynh_chk_set_arr2_u8(bynt_arr2_u8* p, bynt_arr2_u8 v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_arr2_u8(p, file, line);
    return v;
}
helper bynh_chk_move_arr2_u8
static bynt_arr2_u8* bynh_chk_move_arr2_u8(bynt_arr2_u8* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "u8[2]", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_arr2_u8
static bynt_arr2_u8 bynh_chk_ret_arr2_u8(bynt_arr2_u8 v) {
    return v;
}