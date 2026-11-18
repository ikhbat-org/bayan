false bynh_chk_claim_main__Discount bynh_chk_set_main__Discount bynh_chk_move_main__Discount bynh_chk_ret_main__Discount
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_opt_main__Discount bynh_chk_set_opt_main__Discount bynh_chk_move_opt_main__Discount bynh_chk_ret_opt_main__Discount
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
helper bynh_chk_claim_main__Discount
static void bynh_chk_claim_main__Discount(byn_main_Discount* p, const char* file, int line) {
}
helper bynh_chk_set_main__Discount
static byn_main_Discount bynh_chk_set_main__Discount(byn_main_Discount* p, byn_main_Discount v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Discount(p, file, line);
    return v;
}
helper bynh_chk_move_main__Discount
static byn_main_Discount* bynh_chk_move_main__Discount(byn_main_Discount* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Discount", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Discount
static byn_main_Discount bynh_chk_ret_main__Discount(byn_main_Discount v) {
    return v;
}
helper bynh_chk_claim_i64
static void bynh_chk_claim_i64(int64_t* p, const char* file, int line) {
}
helper bynh_chk_set_i64
static int64_t bynh_chk_set_i64(int64_t* p, int64_t v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_i64(p, file, line);
    return v;
}
helper bynh_chk_move_i64
static int64_t* bynh_chk_move_i64(int64_t* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "i64", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_i64
static int64_t bynh_chk_ret_i64(int64_t v) {
    return v;
}
helper bynh_chk_claim_opt_main__Discount
static void bynh_chk_claim_opt_main__Discount(bynt_opt_main__Discount* p, const char* file, int line) {
}
helper bynh_chk_set_opt_main__Discount
static bynt_opt_main__Discount bynh_chk_set_opt_main__Discount(bynt_opt_main__Discount* p, bynt_opt_main__Discount v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_opt_main__Discount(p, file, line);
    return v;
}
helper bynh_chk_move_opt_main__Discount
static bynt_opt_main__Discount* bynh_chk_move_opt_main__Discount(bynt_opt_main__Discount* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Discount\077", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_opt_main__Discount
static bynt_opt_main__Discount bynh_chk_ret_opt_main__Discount(bynt_opt_main__Discount v) {
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