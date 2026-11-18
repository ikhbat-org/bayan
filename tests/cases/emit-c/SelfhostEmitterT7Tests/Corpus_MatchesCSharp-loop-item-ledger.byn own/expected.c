false bynh_chk_claim_span_str bynh_chk_set_span_str bynh_chk_move_span_str bynh_chk_ret_span_str
true bynh_chk_claim_list_str bynh_chk_set_list_str bynh_chk_move_list_str bynh_chk_ret_list_str
true bynh_chk_claim_list_str bynh_chk_set_list_str bynh_chk_move_list_str bynh_chk_ret_list_str
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
true bynh_chk_claim_list_str bynh_chk_set_list_str bynh_chk_move_list_str bynh_chk_ret_list_str
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_span_main__Expense bynh_chk_set_span_main__Expense bynh_chk_move_span_main__Expense bynh_chk_ret_span_main__Expense
true bynh_chk_claim_list_str bynh_chk_set_list_str bynh_chk_move_list_str bynh_chk_ret_list_str
true bynh_chk_claim_list_str bynh_chk_set_list_str bynh_chk_move_list_str bynh_chk_ret_list_str
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
true bynh_chk_claim_list_str bynh_chk_set_list_str bynh_chk_move_list_str bynh_chk_ret_list_str
true bynh_chk_claim_list_main__Expense bynh_chk_set_list_main__Expense bynh_chk_move_list_main__Expense bynh_chk_ret_list_main__Expense
helper bynh_chk_claim_span_str
static void bynh_chk_claim_span_str(bynt_span_str* p, const char* file, int line) {
}
helper bynh_chk_set_span_str
static bynt_span_str bynh_chk_set_span_str(bynt_span_str* p, bynt_span_str v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_span_str(p, file, line);
    return v;
}
helper bynh_chk_move_span_str
static bynt_span_str* bynh_chk_move_span_str(bynt_span_str* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "ReadOnlySpan<string>", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_span_str
static bynt_span_str bynh_chk_ret_span_str(bynt_span_str v) {
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
helper bynh_chk_claim_span_main__Expense
static void bynh_chk_claim_span_main__Expense(bynt_span_main__Expense* p, const char* file, int line) {
}
helper bynh_chk_set_span_main__Expense
static bynt_span_main__Expense bynh_chk_set_span_main__Expense(bynt_span_main__Expense* p, bynt_span_main__Expense v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_span_main__Expense(p, file, line);
    return v;
}
helper bynh_chk_move_span_main__Expense
static bynt_span_main__Expense* bynh_chk_move_span_main__Expense(bynt_span_main__Expense* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "ReadOnlySpan<Expense>", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_span_main__Expense
static bynt_span_main__Expense bynh_chk_ret_span_main__Expense(bynt_span_main__Expense v) {
    return v;
}
helper bynh_chk_claim_list_main__Expense
static void bynh_chk_claim_list_main__Expense(bynt_list_main__Expense* p, const char* file, int line) {
    byn_own_claim((*p).ptr, &(*p), "List<Expense>", file, line);
}
helper bynh_chk_set_list_main__Expense
static bynt_list_main__Expense bynh_chk_set_list_main__Expense(bynt_list_main__Expense* p, bynt_list_main__Expense v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).ptr, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_list_main__Expense(p, file, line);
    return v;
}
helper bynh_chk_move_list_main__Expense
static bynt_list_main__Expense* bynh_chk_move_list_main__Expense(bynt_list_main__Expense* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "List<Expense>", file, line);
    byn_own_release((*p).ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_list_main__Expense
static bynt_list_main__Expense bynh_chk_ret_list_main__Expense(bynt_list_main__Expense v) {
    byn_own_release(v.ptr);
    return v;
}