true bynh_chk_claim_main__Inventory bynh_chk_set_main__Inventory bynh_chk_move_main__Inventory bynh_chk_ret_main__Inventory
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
true bynh_chk_claim_map_str_i64 bynh_chk_set_map_str_i64 bynh_chk_move_map_str_i64 bynh_chk_ret_map_str_i64
true bynh_chk_claim_map_main__Suit_i32 bynh_chk_set_map_main__Suit_i32 bynh_chk_move_map_main__Suit_i32 bynh_chk_ret_map_main__Suit_i32
false bynh_chk_claim_arr6_main__Suit bynh_chk_set_arr6_main__Suit bynh_chk_move_arr6_main__Suit bynh_chk_ret_arr6_main__Suit
true bynh_chk_claim_map_i64_i64 bynh_chk_set_map_i64_i64 bynh_chk_move_map_i64_i64 bynh_chk_ret_map_i64_i64
true bynh_chk_claim_map_rune_bool bynh_chk_set_map_rune_bool bynh_chk_move_map_rune_bool bynh_chk_ret_map_rune_bool
true bynh_chk_claim_map_bool_str bynh_chk_set_map_bool_str bynh_chk_move_map_bool_str bynh_chk_ret_map_bool_str
true bynh_chk_claim_main__Inventory bynh_chk_set_main__Inventory bynh_chk_move_main__Inventory bynh_chk_ret_main__Inventory
true bynh_chk_claim_strbuf bynh_chk_set_strbuf bynh_chk_move_strbuf bynh_chk_ret_strbuf
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
helper bynh_chk_claim_main__Inventory
static void bynh_chk_claim_main__Inventory(bynt_main__Inventory* p, const char* file, int line) {
    byn_own_claim((*p).stock.keys, &(*p).stock, "Map<string, i64>", file, line);
}
helper bynh_chk_set_main__Inventory
static bynt_main__Inventory bynh_chk_set_main__Inventory(bynt_main__Inventory* p, bynt_main__Inventory v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).stock.keys, &(*p).stock);
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Inventory(p, file, line);
    return v;
}
helper bynh_chk_move_main__Inventory
static bynt_main__Inventory* bynh_chk_move_main__Inventory(bynt_main__Inventory* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Inventory", file, line);
    byn_own_release((*p).stock.keys);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Inventory
static bynt_main__Inventory bynh_chk_ret_main__Inventory(bynt_main__Inventory v) {
    byn_own_release(v.stock.keys);
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
helper bynh_chk_claim_map_main__Suit_i32
static void bynh_chk_claim_map_main__Suit_i32(bynt_map_main__Suit_i32* p, const char* file, int line) {
    byn_own_claim((*p).keys, &(*p), "Map<Suit, i32>", file, line);
}
helper bynh_chk_set_map_main__Suit_i32
static bynt_map_main__Suit_i32 bynh_chk_set_map_main__Suit_i32(bynt_map_main__Suit_i32* p, bynt_map_main__Suit_i32 v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).keys, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_map_main__Suit_i32(p, file, line);
    return v;
}
helper bynh_chk_move_map_main__Suit_i32
static bynt_map_main__Suit_i32* bynh_chk_move_map_main__Suit_i32(bynt_map_main__Suit_i32* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Map<Suit, i32>", file, line);
    byn_own_release((*p).keys);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_map_main__Suit_i32
static bynt_map_main__Suit_i32 bynh_chk_ret_map_main__Suit_i32(bynt_map_main__Suit_i32 v) {
    byn_own_release(v.keys);
    return v;
}
helper bynh_chk_claim_arr6_main__Suit
static void bynh_chk_claim_arr6_main__Suit(bynt_arr6_main__Suit* p, const char* file, int line) {
}
helper bynh_chk_set_arr6_main__Suit
static bynt_arr6_main__Suit bynh_chk_set_arr6_main__Suit(bynt_arr6_main__Suit* p, bynt_arr6_main__Suit v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_arr6_main__Suit(p, file, line);
    return v;
}
helper bynh_chk_move_arr6_main__Suit
static bynt_arr6_main__Suit* bynh_chk_move_arr6_main__Suit(bynt_arr6_main__Suit* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Suit[6]", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_arr6_main__Suit
static bynt_arr6_main__Suit bynh_chk_ret_arr6_main__Suit(bynt_arr6_main__Suit v) {
    return v;
}
helper bynh_chk_claim_map_i64_i64
static void bynh_chk_claim_map_i64_i64(bynt_map_i64_i64* p, const char* file, int line) {
    byn_own_claim((*p).keys, &(*p), "Map<i64, i64>", file, line);
}
helper bynh_chk_set_map_i64_i64
static bynt_map_i64_i64 bynh_chk_set_map_i64_i64(bynt_map_i64_i64* p, bynt_map_i64_i64 v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).keys, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_map_i64_i64(p, file, line);
    return v;
}
helper bynh_chk_move_map_i64_i64
static bynt_map_i64_i64* bynh_chk_move_map_i64_i64(bynt_map_i64_i64* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Map<i64, i64>", file, line);
    byn_own_release((*p).keys);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_map_i64_i64
static bynt_map_i64_i64 bynh_chk_ret_map_i64_i64(bynt_map_i64_i64 v) {
    byn_own_release(v.keys);
    return v;
}
helper bynh_chk_claim_map_rune_bool
static void bynh_chk_claim_map_rune_bool(bynt_map_rune_bool* p, const char* file, int line) {
    byn_own_claim((*p).keys, &(*p), "Map<rune, bool>", file, line);
}
helper bynh_chk_set_map_rune_bool
static bynt_map_rune_bool bynh_chk_set_map_rune_bool(bynt_map_rune_bool* p, bynt_map_rune_bool v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).keys, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_map_rune_bool(p, file, line);
    return v;
}
helper bynh_chk_move_map_rune_bool
static bynt_map_rune_bool* bynh_chk_move_map_rune_bool(bynt_map_rune_bool* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Map<rune, bool>", file, line);
    byn_own_release((*p).keys);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_map_rune_bool
static bynt_map_rune_bool bynh_chk_ret_map_rune_bool(bynt_map_rune_bool v) {
    byn_own_release(v.keys);
    return v;
}
helper bynh_chk_claim_map_bool_str
static void bynh_chk_claim_map_bool_str(bynt_map_bool_str* p, const char* file, int line) {
    byn_own_claim((*p).keys, &(*p), "Map<bool, string>", file, line);
}
helper bynh_chk_set_map_bool_str
static bynt_map_bool_str bynh_chk_set_map_bool_str(bynt_map_bool_str* p, bynt_map_bool_str v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).keys, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_map_bool_str(p, file, line);
    return v;
}
helper bynh_chk_move_map_bool_str
static bynt_map_bool_str* bynh_chk_move_map_bool_str(bynt_map_bool_str* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Map<bool, string>", file, line);
    byn_own_release((*p).keys);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_map_bool_str
static bynt_map_bool_str bynh_chk_ret_map_bool_str(bynt_map_bool_str v) {
    byn_own_release(v.keys);
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