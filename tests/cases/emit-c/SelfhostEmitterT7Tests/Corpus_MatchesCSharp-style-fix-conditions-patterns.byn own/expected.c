false bynh_chk_claim_rune bynh_chk_set_rune bynh_chk_move_rune bynh_chk_ret_rune
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_main__Op bynh_chk_set_main__Op bynh_chk_move_main__Op bynh_chk_ret_main__Op
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_main__Box bynh_chk_set_main__Box bynh_chk_move_main__Box bynh_chk_ret_main__Box
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
true bynh_chk_claim_list_i32 bynh_chk_set_list_i32 bynh_chk_move_list_i32 bynh_chk_ret_list_i32
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
true bynh_chk_claim_list_i32 bynh_chk_set_list_i32 bynh_chk_move_list_i32 bynh_chk_ret_list_i32
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
true bynh_chk_claim_list_i32 bynh_chk_set_list_i32 bynh_chk_move_list_i32 bynh_chk_ret_list_i32
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_f64 bynh_chk_set_f64 bynh_chk_move_f64 bynh_chk_ret_f64
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_opt_i32 bynh_chk_set_opt_i32 bynh_chk_move_opt_i32 bynh_chk_ret_opt_i32
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
true bynh_chk_claim_list_i32 bynh_chk_set_list_i32 bynh_chk_move_list_i32 bynh_chk_ret_list_i32
false bynh_chk_claim_main__Box bynh_chk_set_main__Box bynh_chk_move_main__Box bynh_chk_ret_main__Box
helper bynh_chk_claim_rune
static void bynh_chk_claim_rune(uint32_t* p, const char* file, int line) {
}
helper bynh_chk_set_rune
static uint32_t bynh_chk_set_rune(uint32_t* p, uint32_t v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_rune(p, file, line);
    return v;
}
helper bynh_chk_move_rune
static uint32_t* bynh_chk_move_rune(uint32_t* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "rune", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_rune
static uint32_t bynh_chk_ret_rune(uint32_t v) {
    return v;
}
helper bynh_chk_claim_bool
static void bynh_chk_claim_bool(bool* p, const char* file, int line) {
}
helper bynh_chk_set_bool
static bool bynh_chk_set_bool(bool* p, bool v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_bool(p, file, line);
    return v;
}
helper bynh_chk_move_bool
static bool* bynh_chk_move_bool(bool* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "bool", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_bool
static bool bynh_chk_ret_bool(bool v) {
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
helper bynh_chk_claim_main__Op
static void bynh_chk_claim_main__Op(byn_main_Op* p, const char* file, int line) {
}
helper bynh_chk_set_main__Op
static byn_main_Op bynh_chk_set_main__Op(byn_main_Op* p, byn_main_Op v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Op(p, file, line);
    return v;
}
helper bynh_chk_move_main__Op
static byn_main_Op* bynh_chk_move_main__Op(byn_main_Op* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Op", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Op
static byn_main_Op bynh_chk_ret_main__Op(byn_main_Op v) {
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
helper bynh_chk_claim_main__Box
static void bynh_chk_claim_main__Box(bynt_main__Box* p, const char* file, int line) {
}
helper bynh_chk_set_main__Box
static bynt_main__Box bynh_chk_set_main__Box(bynt_main__Box* p, bynt_main__Box v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Box(p, file, line);
    return v;
}
helper bynh_chk_move_main__Box
static bynt_main__Box* bynh_chk_move_main__Box(bynt_main__Box* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Box", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Box
static bynt_main__Box bynh_chk_ret_main__Box(bynt_main__Box v) {
    return v;
}
helper bynh_chk_claim_list_i32
static void bynh_chk_claim_list_i32(bynt_list_i32* p, const char* file, int line) {
    byn_own_claim((*p).ptr, &(*p), "List<i32>", file, line);
}
helper bynh_chk_set_list_i32
static bynt_list_i32 bynh_chk_set_list_i32(bynt_list_i32* p, bynt_list_i32 v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).ptr, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_list_i32(p, file, line);
    return v;
}
helper bynh_chk_move_list_i32
static bynt_list_i32* bynh_chk_move_list_i32(bynt_list_i32* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "List<i32>", file, line);
    byn_own_release((*p).ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_list_i32
static bynt_list_i32 bynh_chk_ret_list_i32(bynt_list_i32 v) {
    byn_own_release(v.ptr);
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
helper bynh_chk_claim_opt_i32
static void bynh_chk_claim_opt_i32(bynt_opt_i32* p, const char* file, int line) {
}
helper bynh_chk_set_opt_i32
static bynt_opt_i32 bynh_chk_set_opt_i32(bynt_opt_i32* p, bynt_opt_i32 v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_opt_i32(p, file, line);
    return v;
}
helper bynh_chk_move_opt_i32
static bynt_opt_i32* bynh_chk_move_opt_i32(bynt_opt_i32* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "i32\077", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_opt_i32
static bynt_opt_i32 bynh_chk_ret_opt_i32(bynt_opt_i32 v) {
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