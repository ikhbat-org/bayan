false bynh_chk_claim_main__Mode bynh_chk_set_main__Mode bynh_chk_move_main__Mode bynh_chk_ret_main__Mode
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_main__Reply bynh_chk_set_main__Reply bynh_chk_move_main__Reply bynh_chk_ret_main__Reply
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
true bynh_chk_claim_list_main__Mode bynh_chk_set_list_main__Mode bynh_chk_move_list_main__Mode bynh_chk_ret_list_main__Mode
helper bynh_chk_claim_main__Mode
static void bynh_chk_claim_main__Mode(byn_main_Mode* p, const char* file, int line) {
}
helper bynh_chk_set_main__Mode
static byn_main_Mode bynh_chk_set_main__Mode(byn_main_Mode* p, byn_main_Mode v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Mode(p, file, line);
    return v;
}
helper bynh_chk_move_main__Mode
static byn_main_Mode* bynh_chk_move_main__Mode(byn_main_Mode* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Mode", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Mode
static byn_main_Mode bynh_chk_ret_main__Mode(byn_main_Mode v) {
    return v;
}
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
helper bynh_chk_claim_main__Reply
static void bynh_chk_claim_main__Reply(byn_main_Reply* p, const char* file, int line) {
}
helper bynh_chk_set_main__Reply
static byn_main_Reply bynh_chk_set_main__Reply(byn_main_Reply* p, byn_main_Reply v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Reply(p, file, line);
    return v;
}
helper bynh_chk_move_main__Reply
static byn_main_Reply* bynh_chk_move_main__Reply(byn_main_Reply* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Reply", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Reply
static byn_main_Reply bynh_chk_ret_main__Reply(byn_main_Reply v) {
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
helper bynh_chk_claim_list_main__Mode
static void bynh_chk_claim_list_main__Mode(bynt_list_main__Mode* p, const char* file, int line) {
    byn_own_claim((*p).ptr, &(*p), "List<Mode>", file, line);
}
helper bynh_chk_set_list_main__Mode
static bynt_list_main__Mode bynh_chk_set_list_main__Mode(bynt_list_main__Mode* p, bynt_list_main__Mode v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).ptr, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_list_main__Mode(p, file, line);
    return v;
}
helper bynh_chk_move_list_main__Mode
static bynt_list_main__Mode* bynh_chk_move_list_main__Mode(bynt_list_main__Mode* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "List<Mode>", file, line);
    byn_own_release((*p).ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_list_main__Mode
static bynt_list_main__Mode bynh_chk_ret_list_main__Mode(bynt_list_main__Mode v) {
    byn_own_release(v.ptr);
    return v;
}