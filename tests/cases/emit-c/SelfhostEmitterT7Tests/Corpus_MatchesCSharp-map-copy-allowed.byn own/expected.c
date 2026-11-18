false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
true bynh_chk_claim_map_str_i64 bynh_chk_set_map_str_i64 bynh_chk_move_map_str_i64 bynh_chk_ret_map_str_i64
true bynh_chk_claim_map_str_i64 bynh_chk_set_map_str_i64 bynh_chk_move_map_str_i64 bynh_chk_ret_map_str_i64
true bynh_chk_claim_map_str_i64 bynh_chk_set_map_str_i64 bynh_chk_move_map_str_i64 bynh_chk_ret_map_str_i64
true bynh_chk_claim_map_str_i64 bynh_chk_set_map_str_i64 bynh_chk_move_map_str_i64 bynh_chk_ret_map_str_i64
true bynh_chk_claim_map_str_i64 bynh_chk_set_map_str_i64 bynh_chk_move_map_str_i64 bynh_chk_ret_map_str_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
true bynh_chk_claim_map_str_i64 bynh_chk_set_map_str_i64 bynh_chk_move_map_str_i64 bynh_chk_ret_map_str_i64
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_res_map_str_i64 bynh_chk_set_res_map_str_i64 bynh_chk_move_res_map_str_i64 bynh_chk_ret_res_map_str_i64
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
true bynh_chk_claim_map_str_i64 bynh_chk_set_map_str_i64 bynh_chk_move_map_str_i64 bynh_chk_ret_map_str_i64
true bynh_chk_claim_map_str_i64 bynh_chk_set_map_str_i64 bynh_chk_move_map_str_i64 bynh_chk_ret_map_str_i64
true bynh_chk_claim_main__Store bynh_chk_set_main__Store bynh_chk_move_main__Store bynh_chk_ret_main__Store
false bynh_chk_claim_main__Slot bynh_chk_set_main__Slot bynh_chk_move_main__Slot bynh_chk_ret_main__Slot
true bynh_chk_claim_list_map_str_i64 bynh_chk_set_list_map_str_i64 bynh_chk_move_list_map_str_i64 bynh_chk_ret_list_map_str_i64
true bynh_chk_claim_map_i64_map_str_i64 bynh_chk_set_map_i64_map_str_i64 bynh_chk_move_map_i64_map_str_i64 bynh_chk_ret_map_i64_map_str_i64
false bynh_chk_claim_arr2_map_str_i64 bynh_chk_set_arr2_map_str_i64 bynh_chk_move_arr2_map_str_i64 bynh_chk_ret_arr2_map_str_i64
true bynh_chk_claim_tup2_map_str_i64_i32 bynh_chk_set_tup2_map_str_i64_i32 bynh_chk_move_tup2_map_str_i64_i32 bynh_chk_ret_tup2_map_str_i64_i32
true bynh_chk_claim_own_map_str_i64 bynh_chk_set_own_map_str_i64 bynh_chk_move_own_map_str_i64 bynh_chk_ret_own_map_str_i64
false bynh_chk_claim_res_map_str_i64 bynh_chk_set_res_map_str_i64 bynh_chk_move_res_map_str_i64 bynh_chk_ret_res_map_str_i64
false bynh_chk_claim_opt_map_str_i64 bynh_chk_set_opt_map_str_i64 bynh_chk_move_opt_map_str_i64 bynh_chk_ret_opt_map_str_i64
true bynh_chk_claim_map_str_i64 bynh_chk_set_map_str_i64 bynh_chk_move_map_str_i64 bynh_chk_ret_map_str_i64
false bynh_chk_claim_main__Counted bynh_chk_set_main__Counted bynh_chk_move_main__Counted bynh_chk_ret_main__Counted
true bynh_chk_claim_main__Named bynh_chk_set_main__Named bynh_chk_move_main__Named bynh_chk_ret_main__Named
true bynh_chk_claim_main__Named bynh_chk_set_main__Named bynh_chk_move_main__Named bynh_chk_ret_main__Named
true bynh_chk_claim_strbuf bynh_chk_set_strbuf bynh_chk_move_strbuf bynh_chk_ret_strbuf
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
true bynh_chk_claim_map_str_i64 bynh_chk_set_map_str_i64 bynh_chk_move_map_str_i64 bynh_chk_ret_map_str_i64
false bynh_chk_claim_main__Counted bynh_chk_set_main__Counted bynh_chk_move_main__Counted bynh_chk_ret_main__Counted
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
helper bynh_chk_claim_map_str_i64
static void bynh_chk_claim_map_str_i64(bynt_map_str_i64* p, const char* file, int line) {
    byn_own_claim((*p).keys, &(*p), "Map<string, i64>", file, line);
}
helper bynh_chk_set_map_str_i64
static bynt_map_str_i64 bynh_chk_set_map_str_i64(bynt_map_str_i64* p, bynt_map_str_i64 v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).keys, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_map_str_i64(p, file, line);
    return v;
}
helper bynh_chk_move_map_str_i64
static bynt_map_str_i64* bynh_chk_move_map_str_i64(bynt_map_str_i64* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Map<string, i64>", file, line);
    byn_own_release((*p).keys);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_map_str_i64
static bynt_map_str_i64 bynh_chk_ret_map_str_i64(bynt_map_str_i64 v) {
    byn_own_release(v.keys);
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
helper bynh_chk_claim_res_map_str_i64
static void bynh_chk_claim_res_map_str_i64(bynt_res_map_str_i64* p, const char* file, int line) {
}
helper bynh_chk_set_res_map_str_i64
static bynt_res_map_str_i64 bynh_chk_set_res_map_str_i64(bynt_res_map_str_i64* p, bynt_res_map_str_i64 v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_res_map_str_i64(p, file, line);
    return v;
}
helper bynh_chk_move_res_map_str_i64
static bynt_res_map_str_i64* bynh_chk_move_res_map_str_i64(bynt_res_map_str_i64* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Result<Map<string, i64>, LookupError>", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_res_map_str_i64
static bynt_res_map_str_i64 bynh_chk_ret_res_map_str_i64(bynt_res_map_str_i64 v) {
    return v;
}
helper bynh_chk_claim_main__Store
static void bynh_chk_claim_main__Store(bynt_main__Store* p, const char* file, int line) {
    byn_own_claim((*p).data.keys, &(*p).data, "Map<string, i64>", file, line);
}
helper bynh_chk_set_main__Store
static bynt_main__Store bynh_chk_set_main__Store(bynt_main__Store* p, bynt_main__Store v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).data.keys, &(*p).data);
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Store(p, file, line);
    return v;
}
helper bynh_chk_move_main__Store
static bynt_main__Store* bynh_chk_move_main__Store(bynt_main__Store* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Store", file, line);
    byn_own_release((*p).data.keys);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Store
static bynt_main__Store bynh_chk_ret_main__Store(bynt_main__Store v) {
    byn_own_release(v.data.keys);
    return v;
}
helper bynh_chk_claim_main__Slot
static void bynh_chk_claim_main__Slot(byn_main_Slot* p, const char* file, int line) {
}
helper bynh_chk_set_main__Slot
static byn_main_Slot bynh_chk_set_main__Slot(byn_main_Slot* p, byn_main_Slot v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Slot(p, file, line);
    return v;
}
helper bynh_chk_move_main__Slot
static byn_main_Slot* bynh_chk_move_main__Slot(byn_main_Slot* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Slot", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Slot
static byn_main_Slot bynh_chk_ret_main__Slot(byn_main_Slot v) {
    return v;
}
helper bynh_chk_claim_list_map_str_i64
static void bynh_chk_claim_list_map_str_i64(bynt_list_map_str_i64* p, const char* file, int line) {
    byn_own_claim((*p).ptr, &(*p), "List<Map<string, i64>>", file, line);
}
helper bynh_chk_set_list_map_str_i64
static bynt_list_map_str_i64 bynh_chk_set_list_map_str_i64(bynt_list_map_str_i64* p, bynt_list_map_str_i64 v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).ptr, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_list_map_str_i64(p, file, line);
    return v;
}
helper bynh_chk_move_list_map_str_i64
static bynt_list_map_str_i64* bynh_chk_move_list_map_str_i64(bynt_list_map_str_i64* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "List<Map<string, i64>>", file, line);
    byn_own_release((*p).ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_list_map_str_i64
static bynt_list_map_str_i64 bynh_chk_ret_list_map_str_i64(bynt_list_map_str_i64 v) {
    byn_own_release(v.ptr);
    return v;
}
helper bynh_chk_claim_map_i64_map_str_i64
static void bynh_chk_claim_map_i64_map_str_i64(bynt_map_i64_map_str_i64* p, const char* file, int line) {
    byn_own_claim((*p).keys, &(*p), "Map<i64, Map<string, i64>>", file, line);
}
helper bynh_chk_set_map_i64_map_str_i64
static bynt_map_i64_map_str_i64 bynh_chk_set_map_i64_map_str_i64(bynt_map_i64_map_str_i64* p, bynt_map_i64_map_str_i64 v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).keys, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_map_i64_map_str_i64(p, file, line);
    return v;
}
helper bynh_chk_move_map_i64_map_str_i64
static bynt_map_i64_map_str_i64* bynh_chk_move_map_i64_map_str_i64(bynt_map_i64_map_str_i64* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Map<i64, Map<string, i64>>", file, line);
    byn_own_release((*p).keys);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_map_i64_map_str_i64
static bynt_map_i64_map_str_i64 bynh_chk_ret_map_i64_map_str_i64(bynt_map_i64_map_str_i64 v) {
    byn_own_release(v.keys);
    return v;
}
helper bynh_chk_claim_arr2_map_str_i64
static void bynh_chk_claim_arr2_map_str_i64(bynt_arr2_map_str_i64* p, const char* file, int line) {
}
helper bynh_chk_set_arr2_map_str_i64
static bynt_arr2_map_str_i64 bynh_chk_set_arr2_map_str_i64(bynt_arr2_map_str_i64* p, bynt_arr2_map_str_i64 v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_arr2_map_str_i64(p, file, line);
    return v;
}
helper bynh_chk_move_arr2_map_str_i64
static bynt_arr2_map_str_i64* bynh_chk_move_arr2_map_str_i64(bynt_arr2_map_str_i64* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Map<string, i64>[2]", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_arr2_map_str_i64
static bynt_arr2_map_str_i64 bynh_chk_ret_arr2_map_str_i64(bynt_arr2_map_str_i64 v) {
    return v;
}
helper bynh_chk_claim_tup2_map_str_i64_i32
static void bynh_chk_claim_tup2_map_str_i64_i32(bynt_tup2_map_str_i64_i32* p, const char* file, int line) {
    byn_own_claim((*p).item1.keys, &(*p).item1, "Map<string, i64>", file, line);
}
helper bynh_chk_set_tup2_map_str_i64_i32
static bynt_tup2_map_str_i64_i32 bynh_chk_set_tup2_map_str_i64_i32(bynt_tup2_map_str_i64_i32* p, bynt_tup2_map_str_i64_i32 v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).item1.keys, &(*p).item1);
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_tup2_map_str_i64_i32(p, file, line);
    return v;
}
helper bynh_chk_move_tup2_map_str_i64_i32
static bynt_tup2_map_str_i64_i32* bynh_chk_move_tup2_map_str_i64_i32(bynt_tup2_map_str_i64_i32* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "(Map<string, i64>, i32)", file, line);
    byn_own_release((*p).item1.keys);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_tup2_map_str_i64_i32
static bynt_tup2_map_str_i64_i32 bynh_chk_ret_tup2_map_str_i64_i32(bynt_tup2_map_str_i64_i32 v) {
    byn_own_release(v.item1.keys);
    return v;
}
helper bynh_chk_claim_own_map_str_i64
static void bynh_chk_claim_own_map_str_i64(bynt_map_str_i64** p, const char* file, int line) {
    byn_own_claim((*p), &(*p), "Owned<Map<string, i64>>", file, line);
}
helper bynh_chk_set_own_map_str_i64
static bynt_map_str_i64* bynh_chk_set_own_map_str_i64(bynt_map_str_i64** p, bynt_map_str_i64* v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p), &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_own_map_str_i64(p, file, line);
    return v;
}
helper bynh_chk_move_own_map_str_i64
static bynt_map_str_i64** bynh_chk_move_own_map_str_i64(bynt_map_str_i64** p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Owned<Map<string, i64>>", file, line);
    byn_own_release((*p));
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_own_map_str_i64
static bynt_map_str_i64* bynh_chk_ret_own_map_str_i64(bynt_map_str_i64* v) {
    byn_own_release(v);
    return v;
}
helper bynh_chk_claim_opt_map_str_i64
static void bynh_chk_claim_opt_map_str_i64(bynt_opt_map_str_i64* p, const char* file, int line) {
}
helper bynh_chk_set_opt_map_str_i64
static bynt_opt_map_str_i64 bynh_chk_set_opt_map_str_i64(bynt_opt_map_str_i64* p, bynt_opt_map_str_i64 v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_opt_map_str_i64(p, file, line);
    return v;
}
helper bynh_chk_move_opt_map_str_i64
static bynt_opt_map_str_i64* bynh_chk_move_opt_map_str_i64(bynt_opt_map_str_i64* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Map<string, i64>\077", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_opt_map_str_i64
static bynt_opt_map_str_i64 bynh_chk_ret_opt_map_str_i64(bynt_opt_map_str_i64 v) {
    return v;
}
helper bynh_chk_claim_main__Counted
static void bynh_chk_claim_main__Counted(bynt_main__Counted* p, const char* file, int line) {
}
helper bynh_chk_set_main__Counted
static bynt_main__Counted bynh_chk_set_main__Counted(bynt_main__Counted* p, bynt_main__Counted v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Counted(p, file, line);
    return v;
}
helper bynh_chk_move_main__Counted
static bynt_main__Counted* bynh_chk_move_main__Counted(bynt_main__Counted* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Counted", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Counted
static bynt_main__Counted bynh_chk_ret_main__Counted(bynt_main__Counted v) {
    return v;
}
helper bynh_chk_claim_main__Named
static void bynh_chk_claim_main__Named(bynt_main__Named* p, const char* file, int line) {
    byn_own_claim((*p).m.keys, &(*p).m, "Map<i64, i64>", file, line);
}
helper bynh_chk_set_main__Named
static bynt_main__Named bynh_chk_set_main__Named(bynt_main__Named* p, bynt_main__Named v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).m.keys, &(*p).m);
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Named(p, file, line);
    return v;
}
helper bynh_chk_move_main__Named
static bynt_main__Named* bynh_chk_move_main__Named(bynt_main__Named* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Named", file, line);
    byn_own_release((*p).m.keys);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Named
static bynt_main__Named bynh_chk_ret_main__Named(bynt_main__Named v) {
    byn_own_release(v.m.keys);
    return v;
}
helper bynh_chk_claim_strbuf
static void bynh_chk_claim_strbuf(byn_writer* p, const char* file, int line) {
    byn_own_claim(((*p).mode == BYN_WRITE_GROW ? (*p).buf : NULL), &(*p), "StrBuf", file, line);
}
helper bynh_chk_set_strbuf
static byn_writer bynh_chk_set_strbuf(byn_writer* p, byn_writer v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop(((*p).mode == BYN_WRITE_GROW ? (*p).buf : NULL), &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_strbuf(p, file, line);
    return v;
}
helper bynh_chk_move_strbuf
static byn_writer* bynh_chk_move_strbuf(byn_writer* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "StrBuf", file, line);
    byn_own_release(((*p).mode == BYN_WRITE_GROW ? (*p).buf : NULL));
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_strbuf
static byn_writer bynh_chk_ret_strbuf(byn_writer v) {
    byn_own_release((v.mode == BYN_WRITE_GROW ? v.buf : NULL));
    return v;
}