false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_main__Signup bynh_chk_set_main__Signup bynh_chk_move_main__Signup bynh_chk_ret_main__Signup
false bynh_chk_claim_main__Address bynh_chk_set_main__Address bynh_chk_move_main__Address bynh_chk_ret_main__Address
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
true bynh_chk_claim_list_builtin__Violation__main__Signup bynh_chk_set_list_builtin__Violation__main__Signup bynh_chk_move_list_builtin__Violation__main__Signup bynh_chk_ret_list_builtin__Violation__main__Signup
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
true bynh_chk_claim_list_builtin__Violation__main__Address bynh_chk_set_list_builtin__Violation__main__Address bynh_chk_move_list_builtin__Violation__main__Address bynh_chk_ret_list_builtin__Violation__main__Address
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
helper bynh_chk_claim_main__Signup
static void bynh_chk_claim_main__Signup(bynt_main__Signup* p, const char* file, int line) {
}
helper bynh_chk_set_main__Signup
static bynt_main__Signup bynh_chk_set_main__Signup(bynt_main__Signup* p, bynt_main__Signup v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Signup(p, file, line);
    return v;
}
helper bynh_chk_move_main__Signup
static bynt_main__Signup* bynh_chk_move_main__Signup(bynt_main__Signup* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Signup", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Signup
static bynt_main__Signup bynh_chk_ret_main__Signup(bynt_main__Signup v) {
    return v;
}
helper bynh_chk_claim_main__Address
static void bynh_chk_claim_main__Address(bynt_main__Address* p, const char* file, int line) {
}
helper bynh_chk_set_main__Address
static bynt_main__Address bynh_chk_set_main__Address(bynt_main__Address* p, bynt_main__Address v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Address(p, file, line);
    return v;
}
helper bynh_chk_move_main__Address
static bynt_main__Address* bynh_chk_move_main__Address(bynt_main__Address* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Address", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Address
static bynt_main__Address bynh_chk_ret_main__Address(bynt_main__Address v) {
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
helper bynh_chk_claim_list_builtin__Violation__main__Signup
static void bynh_chk_claim_list_builtin__Violation__main__Signup(bynt_list_builtin__Violation__main__Signup* p, const char* file, int line) {
    byn_own_claim((*p).ptr, &(*p), "List<Violation<Signup>>", file, line);
}
helper bynh_chk_set_list_builtin__Violation__main__Signup
static bynt_list_builtin__Violation__main__Signup bynh_chk_set_list_builtin__Violation__main__Signup(bynt_list_builtin__Violation__main__Signup* p, bynt_list_builtin__Violation__main__Signup v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).ptr, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_list_builtin__Violation__main__Signup(p, file, line);
    return v;
}
helper bynh_chk_move_list_builtin__Violation__main__Signup
static bynt_list_builtin__Violation__main__Signup* bynh_chk_move_list_builtin__Violation__main__Signup(bynt_list_builtin__Violation__main__Signup* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "List<Violation<Signup>>", file, line);
    byn_own_release((*p).ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_list_builtin__Violation__main__Signup
static bynt_list_builtin__Violation__main__Signup bynh_chk_ret_list_builtin__Violation__main__Signup(bynt_list_builtin__Violation__main__Signup v) {
    byn_own_release(v.ptr);
    return v;
}
helper bynh_chk_claim_list_builtin__Violation__main__Address
static void bynh_chk_claim_list_builtin__Violation__main__Address(bynt_list_builtin__Violation__main__Address* p, const char* file, int line) {
    byn_own_claim((*p).ptr, &(*p), "List<Violation<Address>>", file, line);
}
helper bynh_chk_set_list_builtin__Violation__main__Address
static bynt_list_builtin__Violation__main__Address bynh_chk_set_list_builtin__Violation__main__Address(bynt_list_builtin__Violation__main__Address* p, bynt_list_builtin__Violation__main__Address v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).ptr, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_list_builtin__Violation__main__Address(p, file, line);
    return v;
}
helper bynh_chk_move_list_builtin__Violation__main__Address
static bynt_list_builtin__Violation__main__Address* bynh_chk_move_list_builtin__Violation__main__Address(bynt_list_builtin__Violation__main__Address* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "List<Violation<Address>>", file, line);
    byn_own_release((*p).ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_list_builtin__Violation__main__Address
static bynt_list_builtin__Violation__main__Address bynh_chk_ret_list_builtin__Violation__main__Address(bynt_list_builtin__Violation__main__Address v) {
    byn_own_release(v.ptr);
    return v;
}