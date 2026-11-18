false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
true bynh_chk_claim_main__Bag bynh_chk_set_main__Bag bynh_chk_move_main__Bag bynh_chk_ret_main__Bag
true bynh_chk_claim_list_i32 bynh_chk_set_list_i32 bynh_chk_move_list_i32 bynh_chk_ret_list_i32
true bynh_chk_claim_map_str_i32 bynh_chk_set_map_str_i32 bynh_chk_move_map_str_i32 bynh_chk_ret_map_str_i32
false bynh_chk_claim_main__Point bynh_chk_set_main__Point bynh_chk_move_main__Point bynh_chk_ret_main__Point
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
    byn_own_claim((*p).items.ptr, &(*p).items, "List<i32>", file, line);
    byn_own_claim((*p).counts.keys, &(*p).counts, "Map<string, i32>", file, line);
}
helper bynh_chk_set_main__Bag
static bynt_main__Bag bynh_chk_set_main__Bag(bynt_main__Bag* p, bynt_main__Bag v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).items.ptr, &(*p).items);
    byn_own_drop((*p).counts.keys, &(*p).counts);
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Bag(p, file, line);
    return v;
}
helper bynh_chk_move_main__Bag
static bynt_main__Bag* bynh_chk_move_main__Bag(bynt_main__Bag* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Bag", file, line);
    byn_own_release((*p).items.ptr);
    byn_own_release((*p).counts.keys);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Bag
static bynt_main__Bag bynh_chk_ret_main__Bag(bynt_main__Bag v) {
    byn_own_release(v.items.ptr);
    byn_own_release(v.counts.keys);
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
helper bynh_chk_claim_map_str_i32
static void bynh_chk_claim_map_str_i32(bynt_map_str_i32* p, const char* file, int line) {
    byn_own_claim((*p).keys, &(*p), "Map<string, i32>", file, line);
}
helper bynh_chk_set_map_str_i32
static bynt_map_str_i32 bynh_chk_set_map_str_i32(bynt_map_str_i32* p, bynt_map_str_i32 v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).keys, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_map_str_i32(p, file, line);
    return v;
}
helper bynh_chk_move_map_str_i32
static bynt_map_str_i32* bynh_chk_move_map_str_i32(bynt_map_str_i32* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Map<string, i32>", file, line);
    byn_own_release((*p).keys);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_map_str_i32
static bynt_map_str_i32 bynh_chk_ret_map_str_i32(bynt_map_str_i32 v) {
    byn_own_release(v.keys);
    return v;
}
helper bynh_chk_claim_main__Point
static void bynh_chk_claim_main__Point(bynt_main__Point* p, const char* file, int line) {
}
helper bynh_chk_set_main__Point
static bynt_main__Point bynh_chk_set_main__Point(bynt_main__Point* p, bynt_main__Point v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Point(p, file, line);
    return v;
}
helper bynh_chk_move_main__Point
static bynt_main__Point* bynh_chk_move_main__Point(bynt_main__Point* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Point", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Point
static bynt_main__Point bynh_chk_ret_main__Point(bynt_main__Point v) {
    return v;
}