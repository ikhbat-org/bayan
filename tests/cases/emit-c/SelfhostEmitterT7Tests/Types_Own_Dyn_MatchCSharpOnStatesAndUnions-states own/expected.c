false bynh_chk_claim_main__Lamp bynh_chk_set_main__Lamp bynh_chk_move_main__Lamp bynh_chk_ret_main__Lamp
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_main__Gate bynh_chk_set_main__Gate bynh_chk_move_main__Gate bynh_chk_ret_main__Gate
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_main__Mode bynh_chk_set_main__Mode bynh_chk_move_main__Mode bynh_chk_ret_main__Mode
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_main__Shape bynh_chk_set_main__Shape bynh_chk_move_main__Shape bynh_chk_ret_main__Shape
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
helper bynh_chk_claim_main__Lamp
static void bynh_chk_claim_main__Lamp(bynt_main__Lamp* p, const char* file, int line) {
}
helper bynh_chk_set_main__Lamp
static bynt_main__Lamp bynh_chk_set_main__Lamp(bynt_main__Lamp* p, bynt_main__Lamp v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Lamp(p, file, line);
    return v;
}
helper bynh_chk_move_main__Lamp
static bynt_main__Lamp* bynh_chk_move_main__Lamp(bynt_main__Lamp* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Lamp", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Lamp
static bynt_main__Lamp bynh_chk_ret_main__Lamp(bynt_main__Lamp v) {
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
helper bynh_chk_claim_main__Gate
static void bynh_chk_claim_main__Gate(bynt_main__Gate* p, const char* file, int line) {
}
helper bynh_chk_set_main__Gate
static bynt_main__Gate bynh_chk_set_main__Gate(bynt_main__Gate* p, bynt_main__Gate v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Gate(p, file, line);
    return v;
}
helper bynh_chk_move_main__Gate
static bynt_main__Gate* bynh_chk_move_main__Gate(bynt_main__Gate* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Gate", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Gate
static bynt_main__Gate bynh_chk_ret_main__Gate(bynt_main__Gate v) {
    return v;
}
helper bynh_chk_claim_main__Mode
static void bynh_chk_claim_main__Mode(byn_main_Mode* p, const char* file, int line) {
}
helper bynh_chk_set_main__Mode
static byn_main_Mode bynh_chk_set_main__Mode(byn_main_Mode* p, byn_main_Mode v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Mode(p, file, line);
    return v;
}
helper bynh_chk_move_main__Mode
static byn_main_Mode* bynh_chk_move_main__Mode(byn_main_Mode* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Mode", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Mode
static byn_main_Mode bynh_chk_ret_main__Mode(byn_main_Mode v) {
    return v;
}
helper bynh_chk_claim_main__Shape
static void bynh_chk_claim_main__Shape(byn_main_Shape* p, const char* file, int line) {
}
helper bynh_chk_set_main__Shape
static byn_main_Shape bynh_chk_set_main__Shape(byn_main_Shape* p, byn_main_Shape v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Shape(p, file, line);
    return v;
}
helper bynh_chk_move_main__Shape
static byn_main_Shape* bynh_chk_move_main__Shape(byn_main_Shape* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Shape", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Shape
static byn_main_Shape bynh_chk_ret_main__Shape(byn_main_Shape v) {
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