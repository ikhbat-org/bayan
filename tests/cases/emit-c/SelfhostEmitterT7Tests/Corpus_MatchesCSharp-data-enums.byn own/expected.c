false bynh_chk_claim_main__Planet bynh_chk_set_main__Planet bynh_chk_move_main__Planet bynh_chk_ret_main__Planet
false bynh_chk_claim_f64 bynh_chk_set_f64 bynh_chk_move_f64 bynh_chk_ret_f64
false bynh_chk_claim_main__Planet bynh_chk_set_main__Planet bynh_chk_move_main__Planet bynh_chk_ret_main__Planet
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_main__Planet bynh_chk_set_main__Planet bynh_chk_move_main__Planet bynh_chk_ret_main__Planet
false bynh_chk_claim_main__Planet bynh_chk_set_main__Planet bynh_chk_move_main__Planet bynh_chk_ret_main__Planet
false bynh_chk_claim_main__Planet bynh_chk_set_main__Planet bynh_chk_move_main__Planet bynh_chk_ret_main__Planet
true bynh_chk_claim_list_main__Token bynh_chk_set_list_main__Token bynh_chk_move_list_main__Token bynh_chk_ret_list_main__Token
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
helper bynh_chk_claim_main__Planet
static void bynh_chk_claim_main__Planet(byn_main_Planet* p, const char* file, int line) {
}
helper bynh_chk_set_main__Planet
static byn_main_Planet bynh_chk_set_main__Planet(byn_main_Planet* p, byn_main_Planet v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Planet(p, file, line);
    return v;
}
helper bynh_chk_move_main__Planet
static byn_main_Planet* bynh_chk_move_main__Planet(byn_main_Planet* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Planet", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Planet
static byn_main_Planet bynh_chk_ret_main__Planet(byn_main_Planet v) {
    return v;
}
helper bynh_chk_claim_f64
static void bynh_chk_claim_f64(double* p, const char* file, int line) {
}
helper bynh_chk_set_f64
static double bynh_chk_set_f64(double* p, double v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_f64(p, file, line);
    return v;
}
helper bynh_chk_move_f64
static double* bynh_chk_move_f64(double* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "f64", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_f64
static double bynh_chk_ret_f64(double v) {
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
helper bynh_chk_claim_list_main__Token
static void bynh_chk_claim_list_main__Token(bynt_list_main__Token* p, const char* file, int line) {
    byn_own_claim((*p).ptr, &(*p), "List<Token>", file, line);
}
helper bynh_chk_set_list_main__Token
static bynt_list_main__Token bynh_chk_set_list_main__Token(bynt_list_main__Token* p, bynt_list_main__Token v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).ptr, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_list_main__Token(p, file, line);
    return v;
}
helper bynh_chk_move_list_main__Token
static bynt_list_main__Token* bynh_chk_move_list_main__Token(bynt_list_main__Token* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "List<Token>", file, line);
    byn_own_release((*p).ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_list_main__Token
static bynt_list_main__Token bynh_chk_ret_list_main__Token(bynt_list_main__Token v) {
    byn_own_release(v.ptr);
    return v;
}
helper bynh_chk_claim_i32
static void bynh_chk_claim_i32(int32_t* p, const char* file, int line) {
}
helper bynh_chk_set_i32
static int32_t bynh_chk_set_i32(int32_t* p, int32_t v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_i32(p, file, line);
    return v;
}
helper bynh_chk_move_i32
static int32_t* bynh_chk_move_i32(int32_t* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "i32", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_i32
static int32_t bynh_chk_ret_i32(int32_t v) {
    return v;
}