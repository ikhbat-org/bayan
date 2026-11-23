false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_main__Box bynh_chk_set_main__Box bynh_chk_move_main__Box bynh_chk_ret_main__Box
false bynh_chk_claim_main__Box bynh_chk_set_main__Box bynh_chk_move_main__Box bynh_chk_ret_main__Box
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_main__Box bynh_chk_set_main__Box bynh_chk_move_main__Box bynh_chk_ret_main__Box
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_main__Qty bynh_chk_set_main__Qty bynh_chk_move_main__Qty bynh_chk_ret_main__Qty
false bynh_chk_claim_main__Qty bynh_chk_set_main__Qty bynh_chk_move_main__Qty bynh_chk_ret_main__Qty
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_main__Box bynh_chk_set_main__Box bynh_chk_move_main__Box bynh_chk_ret_main__Box
false bynh_chk_claim_main__Box bynh_chk_set_main__Box bynh_chk_move_main__Box bynh_chk_ret_main__Box
false bynh_chk_claim_main__Box bynh_chk_set_main__Box bynh_chk_move_main__Box bynh_chk_ret_main__Box
false bynh_chk_claim_main__Box bynh_chk_set_main__Box bynh_chk_move_main__Box bynh_chk_ret_main__Box
false bynh_chk_claim_main__Box bynh_chk_set_main__Box bynh_chk_move_main__Box bynh_chk_ret_main__Box
false bynh_chk_claim_main__Box bynh_chk_set_main__Box bynh_chk_move_main__Box bynh_chk_ret_main__Box
false bynh_chk_claim_main__Qty bynh_chk_set_main__Qty bynh_chk_move_main__Qty bynh_chk_ret_main__Qty
false bynh_chk_claim_main__Qty bynh_chk_set_main__Qty bynh_chk_move_main__Qty bynh_chk_ret_main__Qty
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
true bynh_chk_claim_list_builtin__Violation__main__Box bynh_chk_set_list_builtin__Violation__main__Box bynh_chk_move_list_builtin__Violation__main__Box bynh_chk_ret_list_builtin__Violation__main__Box
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
helper bynh_chk_claim_main__Qty
static void bynh_chk_claim_main__Qty(bynt_main__Qty* p, const char* file, int line) {
}
helper bynh_chk_set_main__Qty
static bynt_main__Qty bynh_chk_set_main__Qty(bynt_main__Qty* p, bynt_main__Qty v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Qty(p, file, line);
    return v;
}
helper bynh_chk_move_main__Qty
static bynt_main__Qty* bynh_chk_move_main__Qty(bynt_main__Qty* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Qty", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Qty
static bynt_main__Qty bynh_chk_ret_main__Qty(bynt_main__Qty v) {
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
helper bynh_chk_claim_list_builtin__Violation__main__Box
static void bynh_chk_claim_list_builtin__Violation__main__Box(bynt_list_builtin__Violation__main__Box* p, const char* file, int line) {
    byn_own_claim((*p).ptr, &(*p), "List<Violation<Box>>", file, line);
}
helper bynh_chk_set_list_builtin__Violation__main__Box
static bynt_list_builtin__Violation__main__Box bynh_chk_set_list_builtin__Violation__main__Box(bynt_list_builtin__Violation__main__Box* p, bynt_list_builtin__Violation__main__Box v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).ptr, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_list_builtin__Violation__main__Box(p, file, line);
    return v;
}
helper bynh_chk_move_list_builtin__Violation__main__Box
static bynt_list_builtin__Violation__main__Box* bynh_chk_move_list_builtin__Violation__main__Box(bynt_list_builtin__Violation__main__Box* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "List<Violation<Box>>", file, line);
    byn_own_release((*p).ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_list_builtin__Violation__main__Box
static bynt_list_builtin__Violation__main__Box bynh_chk_ret_list_builtin__Violation__main__Box(bynt_list_builtin__Violation__main__Box v) {
    byn_own_release(v.ptr);
    return v;
}