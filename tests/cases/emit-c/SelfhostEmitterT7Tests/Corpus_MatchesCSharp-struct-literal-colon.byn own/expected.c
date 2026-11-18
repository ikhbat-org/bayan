false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_main__LineItem bynh_chk_set_main__LineItem bynh_chk_move_main__LineItem bynh_chk_ret_main__LineItem
false bynh_chk_claim_main__LineItem bynh_chk_set_main__LineItem bynh_chk_move_main__LineItem bynh_chk_ret_main__LineItem
false bynh_chk_claim_main__Money bynh_chk_set_main__Money bynh_chk_move_main__Money bynh_chk_ret_main__Money
true bynh_chk_claim_strbuf bynh_chk_set_strbuf bynh_chk_move_strbuf bynh_chk_ret_strbuf
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
true bynh_chk_claim_strbuf bynh_chk_set_strbuf bynh_chk_move_strbuf bynh_chk_ret_strbuf
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
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
helper bynh_chk_claim_main__LineItem
static void bynh_chk_claim_main__LineItem(bynt_main__LineItem* p, const char* file, int line) {
}
helper bynh_chk_set_main__LineItem
static bynt_main__LineItem bynh_chk_set_main__LineItem(bynt_main__LineItem* p, bynt_main__LineItem v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__LineItem(p, file, line);
    return v;
}
helper bynh_chk_move_main__LineItem
static bynt_main__LineItem* bynh_chk_move_main__LineItem(bynt_main__LineItem* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "LineItem", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__LineItem
static bynt_main__LineItem bynh_chk_ret_main__LineItem(bynt_main__LineItem v) {
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