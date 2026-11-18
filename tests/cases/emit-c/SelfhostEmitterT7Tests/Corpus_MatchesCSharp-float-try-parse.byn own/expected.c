false bynh_chk_claim_opt_f64 bynh_chk_set_opt_f64 bynh_chk_move_opt_f64 bynh_chk_ret_opt_f64
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_opt_f32 bynh_chk_set_opt_f32 bynh_chk_move_opt_f32 bynh_chk_ret_opt_f32
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
helper bynh_chk_claim_opt_f64
static void bynh_chk_claim_opt_f64(bynt_opt_f64* p, const char* file, int line) {
}
helper bynh_chk_set_opt_f64
static bynt_opt_f64 bynh_chk_set_opt_f64(bynt_opt_f64* p, bynt_opt_f64 v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_opt_f64(p, file, line);
    return v;
}
helper bynh_chk_move_opt_f64
static bynt_opt_f64* bynh_chk_move_opt_f64(bynt_opt_f64* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "f64\077", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_opt_f64
static bynt_opt_f64 bynh_chk_ret_opt_f64(bynt_opt_f64 v) {
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
helper bynh_chk_claim_opt_f32
static void bynh_chk_claim_opt_f32(bynt_opt_f32* p, const char* file, int line) {
}
helper bynh_chk_set_opt_f32
static bynt_opt_f32 bynh_chk_set_opt_f32(bynt_opt_f32* p, bynt_opt_f32 v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_opt_f32(p, file, line);
    return v;
}
helper bynh_chk_move_opt_f32
static bynt_opt_f32* bynh_chk_move_opt_f32(bynt_opt_f32* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "f32\077", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_opt_f32
static bynt_opt_f32 bynh_chk_ret_opt_f32(bynt_opt_f32 v) {
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