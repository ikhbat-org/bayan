false bynh_chk_claim_main__Order bynh_chk_set_main__Order bynh_chk_move_main__Order bynh_chk_ret_main__Order
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_main__Order bynh_chk_set_main__Order bynh_chk_move_main__Order bynh_chk_ret_main__Order
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_main__Order bynh_chk_set_main__Order bynh_chk_move_main__Order bynh_chk_ret_main__Order
false bynh_chk_claim_main__Order bynh_chk_set_main__Order bynh_chk_move_main__Order bynh_chk_ret_main__Order
false bynh_chk_claim_main__Order bynh_chk_set_main__Order bynh_chk_move_main__Order bynh_chk_ret_main__Order
false bynh_chk_claim_opt_main__Order bynh_chk_set_opt_main__Order bynh_chk_move_opt_main__Order bynh_chk_ret_opt_main__Order
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
helper bynh_chk_claim_main__Order
static void bynh_chk_claim_main__Order(bynt_main__Order* p, const char* file, int line) {
}
helper bynh_chk_set_main__Order
static bynt_main__Order bynh_chk_set_main__Order(bynt_main__Order* p, bynt_main__Order v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Order(p, file, line);
    return v;
}
helper bynh_chk_move_main__Order
static bynt_main__Order* bynh_chk_move_main__Order(bynt_main__Order* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Order", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Order
static bynt_main__Order bynh_chk_ret_main__Order(bynt_main__Order v) {
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
helper bynh_chk_claim_opt_main__Order
static void bynh_chk_claim_opt_main__Order(bynt_opt_main__Order* p, const char* file, int line) {
}
helper bynh_chk_set_opt_main__Order
static bynt_opt_main__Order bynh_chk_set_opt_main__Order(bynt_opt_main__Order* p, bynt_opt_main__Order v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_opt_main__Order(p, file, line);
    return v;
}
helper bynh_chk_move_opt_main__Order
static bynt_opt_main__Order* bynh_chk_move_opt_main__Order(bynt_opt_main__Order* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Order\077", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_opt_main__Order
static bynt_opt_main__Order bynh_chk_ret_opt_main__Order(bynt_opt_main__Order v) {
    return v;
}