false bynh_chk_claim_span_str bynh_chk_set_span_str bynh_chk_move_span_str bynh_chk_ret_span_str
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
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