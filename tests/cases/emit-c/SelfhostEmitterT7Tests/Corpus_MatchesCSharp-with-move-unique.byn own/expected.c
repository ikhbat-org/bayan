false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
true bynh_chk_claim_list_i64 bynh_chk_set_list_i64 bynh_chk_move_list_i64 bynh_chk_ret_list_i64
true bynh_chk_claim_main__Ledger bynh_chk_set_main__Ledger bynh_chk_move_main__Ledger bynh_chk_ret_main__Ledger
true bynh_chk_claim_main__Ledger bynh_chk_set_main__Ledger bynh_chk_move_main__Ledger bynh_chk_ret_main__Ledger
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
helper bynh_chk_claim_main__Ledger
static void bynh_chk_claim_main__Ledger(bynt_main__Ledger* p, const char* file, int line) {
    byn_own_claim((*p).items.ptr, &(*p).items, "List<i64>", file, line);
}
helper bynh_chk_set_main__Ledger
static bynt_main__Ledger bynh_chk_set_main__Ledger(bynt_main__Ledger* p, bynt_main__Ledger v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).items.ptr, &(*p).items);
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Ledger(p, file, line);
    return v;
}
helper bynh_chk_move_main__Ledger
static bynt_main__Ledger* bynh_chk_move_main__Ledger(bynt_main__Ledger* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Ledger", file, line);
    byn_own_release((*p).items.ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Ledger
static bynt_main__Ledger bynh_chk_ret_main__Ledger(bynt_main__Ledger v) {
    byn_own_release(v.items.ptr);
    return v;
}