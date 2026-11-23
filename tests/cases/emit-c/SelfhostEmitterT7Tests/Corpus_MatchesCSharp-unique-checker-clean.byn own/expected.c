true bynh_chk_claim_list_i64 bynh_chk_set_list_i64 bynh_chk_move_list_i64 bynh_chk_ret_list_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
true bynh_chk_claim_list_i64 bynh_chk_set_list_i64 bynh_chk_move_list_i64 bynh_chk_ret_list_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
true bynh_chk_claim_list_i64 bynh_chk_set_list_i64 bynh_chk_move_list_i64 bynh_chk_ret_list_i64
true bynh_chk_claim_list_i64 bynh_chk_set_list_i64 bynh_chk_move_list_i64 bynh_chk_ret_list_i64
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
true bynh_chk_claim_main__Bag bynh_chk_set_main__Bag bynh_chk_move_main__Bag bynh_chk_ret_main__Bag
true bynh_chk_claim_list_i64 bynh_chk_set_list_i64 bynh_chk_move_list_i64 bynh_chk_ret_list_i64
true bynh_chk_claim_main__Bag bynh_chk_set_main__Bag bynh_chk_move_main__Bag bynh_chk_ret_main__Bag
false bynh_chk_claim_main__Payload bynh_chk_set_main__Payload bynh_chk_move_main__Payload bynh_chk_ret_main__Payload
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
true bynh_chk_claim_list_list_i64 bynh_chk_set_list_list_i64 bynh_chk_move_list_list_i64 bynh_chk_ret_list_list_i64
true bynh_chk_claim_list_i64 bynh_chk_set_list_i64 bynh_chk_move_list_i64 bynh_chk_ret_list_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
true bynh_chk_claim_list_i64 bynh_chk_set_list_i64 bynh_chk_move_list_i64 bynh_chk_ret_list_i64
true bynh_chk_claim_main__Bag bynh_chk_set_main__Bag bynh_chk_move_main__Bag bynh_chk_ret_main__Bag
true bynh_chk_claim_main__Bag bynh_chk_set_main__Bag bynh_chk_move_main__Bag bynh_chk_ret_main__Bag
true bynh_chk_claim_list_i64 bynh_chk_set_list_i64 bynh_chk_move_list_i64 bynh_chk_ret_list_i64
true bynh_chk_claim_map_str_i64 bynh_chk_set_map_str_i64 bynh_chk_move_map_str_i64 bynh_chk_ret_map_str_i64
true bynh_chk_claim_map_str_i64 bynh_chk_set_map_str_i64 bynh_chk_move_map_str_i64 bynh_chk_ret_map_str_i64
true bynh_chk_claim_strbuf bynh_chk_set_strbuf bynh_chk_move_strbuf bynh_chk_ret_strbuf
true bynh_chk_claim_strbuf bynh_chk_set_strbuf bynh_chk_move_strbuf bynh_chk_ret_strbuf
false bynh_chk_claim_main__Payload bynh_chk_set_main__Payload bynh_chk_move_main__Payload bynh_chk_ret_main__Payload
true bynh_chk_claim_list_i64 bynh_chk_set_list_i64 bynh_chk_move_list_i64 bynh_chk_ret_list_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
helper bynh_chk_claim_list_i64
static void bynh_chk_claim_list_i64(bynt_list_i64* p, const char* file, int line) {
    byn_own_claim((*p).ptr, &(*p), "List<i64>", file, line);
}
helper bynh_chk_set_list_i64
static bynt_list_i64 bynh_chk_set_list_i64(bynt_list_i64* p, bynt_list_i64 v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).ptr, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_list_i64(p, file, line);
    return v;
}
helper bynh_chk_move_list_i64
static bynt_list_i64* bynh_chk_move_list_i64(bynt_list_i64* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "List<i64>", file, line);
    byn_own_release((*p).ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_list_i64
static bynt_list_i64 bynh_chk_ret_list_i64(bynt_list_i64 v) {
    byn_own_release(v.ptr);
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
helper bynh_chk_claim_main__Bag
static void bynh_chk_claim_main__Bag(bynt_main__Bag* p, const char* file, int line) {
    byn_own_claim((*p).items.ptr, &(*p).items, "List<i64>", file, line);
}
helper bynh_chk_set_main__Bag
static bynt_main__Bag bynh_chk_set_main__Bag(bynt_main__Bag* p, bynt_main__Bag v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).items.ptr, &(*p).items);
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Bag(p, file, line);
    return v;
}
helper bynh_chk_move_main__Bag
static bynt_main__Bag* bynh_chk_move_main__Bag(bynt_main__Bag* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Bag", file, line);
    byn_own_release((*p).items.ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Bag
static bynt_main__Bag bynh_chk_ret_main__Bag(bynt_main__Bag v) {
    byn_own_release(v.items.ptr);
    return v;
}
helper bynh_chk_claim_main__Payload
static void bynh_chk_claim_main__Payload(byn_main_Payload* p, const char* file, int line) {
}
helper bynh_chk_set_main__Payload
static byn_main_Payload bynh_chk_set_main__Payload(byn_main_Payload* p, byn_main_Payload v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Payload(p, file, line);
    return v;
}
helper bynh_chk_move_main__Payload
static byn_main_Payload* bynh_chk_move_main__Payload(byn_main_Payload* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Payload", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Payload
static byn_main_Payload bynh_chk_ret_main__Payload(byn_main_Payload v) {
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
helper bynh_chk_claim_list_list_i64
static void bynh_chk_claim_list_list_i64(bynt_list_list_i64* p, const char* file, int line) {
    byn_own_claim((*p).ptr, &(*p), "List<List<i64>>", file, line);
}
helper bynh_chk_set_list_list_i64
static bynt_list_list_i64 bynh_chk_set_list_list_i64(bynt_list_list_i64* p, bynt_list_list_i64 v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).ptr, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_list_list_i64(p, file, line);
    return v;
}
helper bynh_chk_move_list_list_i64
static bynt_list_list_i64* bynh_chk_move_list_list_i64(bynt_list_list_i64* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "List<List<i64>>", file, line);
    byn_own_release((*p).ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_list_list_i64
static bynt_list_list_i64 bynh_chk_ret_list_list_i64(bynt_list_list_i64 v) {
    byn_own_release(v.ptr);
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