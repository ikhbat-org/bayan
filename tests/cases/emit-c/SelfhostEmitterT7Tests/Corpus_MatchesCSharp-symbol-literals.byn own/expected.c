false bynh_chk_claim_sym bynh_chk_set_sym bynh_chk_move_sym bynh_chk_ret_sym
false bynh_chk_claim_sym bynh_chk_set_sym bynh_chk_move_sym bynh_chk_ret_sym
false bynh_chk_claim_sym bynh_chk_set_sym bynh_chk_move_sym bynh_chk_ret_sym
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_sym bynh_chk_set_sym bynh_chk_move_sym bynh_chk_ret_sym
false bynh_chk_claim_sym bynh_chk_set_sym bynh_chk_move_sym bynh_chk_ret_sym
false bynh_chk_claim_opt_sym bynh_chk_set_opt_sym bynh_chk_move_opt_sym bynh_chk_ret_opt_sym
false bynh_chk_claim_main__Entry bynh_chk_set_main__Entry bynh_chk_move_main__Entry bynh_chk_ret_main__Entry
false bynh_chk_claim_main__Entry bynh_chk_set_main__Entry bynh_chk_move_main__Entry bynh_chk_ret_main__Entry
true bynh_chk_claim_list_sym bynh_chk_set_list_sym bynh_chk_move_list_sym bynh_chk_ret_list_sym
true bynh_chk_claim_map_sym_i32 bynh_chk_set_map_sym_i32 bynh_chk_move_map_sym_i32 bynh_chk_ret_map_sym_i32
helper bynh_chk_claim_sym
static void bynh_chk_claim_sym(byn_sym* p, const char* file, int line) {
}
helper bynh_chk_set_sym
static byn_sym bynh_chk_set_sym(byn_sym* p, byn_sym v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_sym(p, file, line);
    return v;
}
helper bynh_chk_move_sym
static byn_sym* bynh_chk_move_sym(byn_sym* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Symbol", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_sym
static byn_sym bynh_chk_ret_sym(byn_sym v) {
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
helper bynh_chk_claim_opt_sym
static void bynh_chk_claim_opt_sym(bynt_opt_sym* p, const char* file, int line) {
}
helper bynh_chk_set_opt_sym
static bynt_opt_sym bynh_chk_set_opt_sym(bynt_opt_sym* p, bynt_opt_sym v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_opt_sym(p, file, line);
    return v;
}
helper bynh_chk_move_opt_sym
static bynt_opt_sym* bynh_chk_move_opt_sym(bynt_opt_sym* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Symbol\077", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_opt_sym
static bynt_opt_sym bynh_chk_ret_opt_sym(bynt_opt_sym v) {
    return v;
}
helper bynh_chk_claim_main__Entry
static void bynh_chk_claim_main__Entry(bynt_main__Entry* p, const char* file, int line) {
}
helper bynh_chk_set_main__Entry
static bynt_main__Entry bynh_chk_set_main__Entry(bynt_main__Entry* p, bynt_main__Entry v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Entry(p, file, line);
    return v;
}
helper bynh_chk_move_main__Entry
static bynt_main__Entry* bynh_chk_move_main__Entry(bynt_main__Entry* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Entry", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Entry
static bynt_main__Entry bynh_chk_ret_main__Entry(bynt_main__Entry v) {
    return v;
}
helper bynh_chk_claim_list_sym
static void bynh_chk_claim_list_sym(bynt_list_sym* p, const char* file, int line) {
    byn_own_claim((*p).ptr, &(*p), "List<Symbol>", file, line);
}
helper bynh_chk_set_list_sym
static bynt_list_sym bynh_chk_set_list_sym(bynt_list_sym* p, bynt_list_sym v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).ptr, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_list_sym(p, file, line);
    return v;
}
helper bynh_chk_move_list_sym
static bynt_list_sym* bynh_chk_move_list_sym(bynt_list_sym* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "List<Symbol>", file, line);
    byn_own_release((*p).ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_list_sym
static bynt_list_sym bynh_chk_ret_list_sym(bynt_list_sym v) {
    byn_own_release(v.ptr);
    return v;
}
helper bynh_chk_claim_map_sym_i32
static void bynh_chk_claim_map_sym_i32(bynt_map_sym_i32* p, const char* file, int line) {
    byn_own_claim((*p).keys, &(*p), "Map<Symbol, i32>", file, line);
}
helper bynh_chk_set_map_sym_i32
static bynt_map_sym_i32 bynh_chk_set_map_sym_i32(bynt_map_sym_i32* p, bynt_map_sym_i32 v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).keys, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_map_sym_i32(p, file, line);
    return v;
}
helper bynh_chk_move_map_sym_i32
static bynt_map_sym_i32* bynh_chk_move_map_sym_i32(bynt_map_sym_i32* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Map<Symbol, i32>", file, line);
    byn_own_release((*p).keys);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_map_sym_i32
static bynt_map_sym_i32 bynh_chk_ret_map_sym_i32(bynt_map_sym_i32 v) {
    byn_own_release(v.keys);
    return v;
}