false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
true bynh_chk_claim_main__Bag bynh_chk_set_main__Bag bynh_chk_move_main__Bag bynh_chk_ret_main__Bag
false bynh_chk_claim_dyn_main__IThing bynh_chk_set_dyn_main__IThing bynh_chk_move_dyn_main__IThing bynh_chk_ret_dyn_main__IThing
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_dyn_main__IThing bynh_chk_set_dyn_main__IThing bynh_chk_move_dyn_main__IThing bynh_chk_ret_dyn_main__IThing
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
helper bynh_chk_claim_main__Bag
static void bynh_chk_claim_main__Bag(bynt_main__Bag* p, const char* file, int line) {
    byn_own_claim((*p).items.keys, &(*p).items, "Map<i64, S>", file, line);
}
helper bynh_chk_set_main__Bag
static bynt_main__Bag bynh_chk_set_main__Bag(bynt_main__Bag* p, bynt_main__Bag v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).items.keys, &(*p).items);
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Bag(p, file, line);
    return v;
}
helper bynh_chk_move_main__Bag
static bynt_main__Bag* bynh_chk_move_main__Bag(bynt_main__Bag* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Bag", file, line);
    byn_own_release((*p).items.keys);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Bag
static bynt_main__Bag bynh_chk_ret_main__Bag(bynt_main__Bag v) {
    byn_own_release(v.items.keys);
    return v;
}
helper bynh_chk_claim_dyn_main__IThing
static void bynh_chk_claim_dyn_main__IThing(byn_dyn_main__IThing* p, const char* file, int line) {
}
helper bynh_chk_set_dyn_main__IThing
static byn_dyn_main__IThing bynh_chk_set_dyn_main__IThing(byn_dyn_main__IThing* p, byn_dyn_main__IThing v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_dyn_main__IThing(p, file, line);
    return v;
}
helper bynh_chk_move_dyn_main__IThing
static byn_dyn_main__IThing* bynh_chk_move_dyn_main__IThing(byn_dyn_main__IThing* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "dyn ref IThing", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_dyn_main__IThing
static byn_dyn_main__IThing bynh_chk_ret_dyn_main__IThing(byn_dyn_main__IThing v) {
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