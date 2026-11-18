false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_arr2_main__Mode bynh_chk_set_arr2_main__Mode bynh_chk_move_arr2_main__Mode bynh_chk_ret_arr2_main__Mode
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_main__Particle bynh_chk_set_main__Particle bynh_chk_move_main__Particle bynh_chk_ret_main__Particle
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
helper bynh_chk_claim_arr2_main__Mode
static void bynh_chk_claim_arr2_main__Mode(bynt_arr2_main__Mode* p, const char* file, int line) {
}
helper bynh_chk_set_arr2_main__Mode
static bynt_arr2_main__Mode bynh_chk_set_arr2_main__Mode(bynt_arr2_main__Mode* p, bynt_arr2_main__Mode v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_arr2_main__Mode(p, file, line);
    return v;
}
helper bynh_chk_move_arr2_main__Mode
static bynt_arr2_main__Mode* bynh_chk_move_arr2_main__Mode(bynt_arr2_main__Mode* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Mode[2]", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_arr2_main__Mode
static bynt_arr2_main__Mode bynh_chk_ret_arr2_main__Mode(bynt_arr2_main__Mode v) {
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
helper bynh_chk_claim_main__Particle
static void bynh_chk_claim_main__Particle(bynt_main__Particle* p, const char* file, int line) {
}
helper bynh_chk_set_main__Particle
static bynt_main__Particle bynh_chk_set_main__Particle(bynt_main__Particle* p, bynt_main__Particle v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Particle(p, file, line);
    return v;
}
helper bynh_chk_move_main__Particle
static bynt_main__Particle* bynh_chk_move_main__Particle(bynt_main__Particle* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Particle", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Particle
static bynt_main__Particle bynh_chk_ret_main__Particle(bynt_main__Particle v) {
    return v;
}