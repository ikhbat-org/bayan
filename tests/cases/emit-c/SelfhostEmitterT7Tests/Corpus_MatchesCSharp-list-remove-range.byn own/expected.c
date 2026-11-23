true bynh_chk_claim_list_i64 bynh_chk_set_list_i64 bynh_chk_move_list_i64 bynh_chk_ret_list_i64
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
true bynh_chk_claim_strbuf bynh_chk_set_strbuf bynh_chk_move_strbuf bynh_chk_ret_strbuf
true bynh_chk_claim_list_i64 bynh_chk_set_list_i64 bynh_chk_move_list_i64 bynh_chk_ret_list_i64
true bynh_chk_claim_list_i64 bynh_chk_set_list_i64 bynh_chk_move_list_i64 bynh_chk_ret_list_i64
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
true bynh_chk_claim_list_i64 bynh_chk_set_list_i64 bynh_chk_move_list_i64 bynh_chk_ret_list_i64
true bynh_chk_claim_list_i64 bynh_chk_set_list_i64 bynh_chk_move_list_i64 bynh_chk_ret_list_i64
true bynh_chk_claim_list_i64 bynh_chk_set_list_i64 bynh_chk_move_list_i64 bynh_chk_ret_list_i64
true bynh_chk_claim_list_i64 bynh_chk_set_list_i64 bynh_chk_move_list_i64 bynh_chk_ret_list_i64
true bynh_chk_claim_list_i64 bynh_chk_set_list_i64 bynh_chk_move_list_i64 bynh_chk_ret_list_i64
true bynh_chk_claim_list_str bynh_chk_set_list_str bynh_chk_move_list_str bynh_chk_ret_list_str
false bynh_chk_claim_arr5_str bynh_chk_set_arr5_str bynh_chk_move_arr5_str bynh_chk_ret_arr5_str
true bynh_chk_claim_strbuf bynh_chk_set_strbuf bynh_chk_move_strbuf bynh_chk_ret_strbuf
helper bynh_chk_claim_list_i64
static void bynh_chk_claim_list_i64(bynt_list_i64* p, const char* file, int line) {
    byn_own_claim((*p).ptr, &(*p), "List<i64>", file, line);
}
helper bynh_chk_set_list_i64
static bynt_list_i64 bynh_chk_set_list_i64(bynt_list_i64* p, bynt_list_i64 v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).ptr, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_list_i64(p, file, line);
    return v;
}
helper bynh_chk_move_list_i64
static bynt_list_i64* bynh_chk_move_list_i64(bynt_list_i64* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "List<i64>", file, line);
    byn_own_release((*p).ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_list_i64
static bynt_list_i64 bynh_chk_ret_list_i64(bynt_list_i64 v) {
    byn_own_release(v.ptr);
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
helper bynh_chk_claim_strbuf
static void bynh_chk_claim_strbuf(byn_writer* p, const char* file, int line) {
    byn_own_claim(((*p).mode == BYN_WRITE_GROW ? (*p).buf : NULL), &(*p), "StrBuf", file, line);
}
helper bynh_chk_set_strbuf
static byn_writer bynh_chk_set_strbuf(byn_writer* p, byn_writer v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop(((*p).mode == BYN_WRITE_GROW ? (*p).buf : NULL), &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_strbuf(p, file, line);
    return v;
}
helper bynh_chk_move_strbuf
static byn_writer* bynh_chk_move_strbuf(byn_writer* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "StrBuf", file, line);
    byn_own_release(((*p).mode == BYN_WRITE_GROW ? (*p).buf : NULL));
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_strbuf
static byn_writer bynh_chk_ret_strbuf(byn_writer v) {
    byn_own_release((v.mode == BYN_WRITE_GROW ? v.buf : NULL));
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
helper bynh_chk_claim_list_str
static void bynh_chk_claim_list_str(bynt_list_str* p, const char* file, int line) {
    byn_own_claim((*p).ptr, &(*p), "List<string>", file, line);
}
helper bynh_chk_set_list_str
static bynt_list_str bynh_chk_set_list_str(bynt_list_str* p, bynt_list_str v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).ptr, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_list_str(p, file, line);
    return v;
}
helper bynh_chk_move_list_str
static bynt_list_str* bynh_chk_move_list_str(bynt_list_str* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "List<string>", file, line);
    byn_own_release((*p).ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_list_str
static bynt_list_str bynh_chk_ret_list_str(bynt_list_str v) {
    byn_own_release(v.ptr);
    return v;
}
helper bynh_chk_claim_arr5_str
static void bynh_chk_claim_arr5_str(bynt_arr5_str* p, const char* file, int line) {
}
helper bynh_chk_set_arr5_str
static bynt_arr5_str bynh_chk_set_arr5_str(bynt_arr5_str* p, bynt_arr5_str v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_arr5_str(p, file, line);
    return v;
}
helper bynh_chk_move_arr5_str
static bynt_arr5_str* bynh_chk_move_arr5_str(bynt_arr5_str* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "string[5]", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_arr5_str
static bynt_arr5_str bynh_chk_ret_arr5_str(bynt_arr5_str v) {
    return v;
}