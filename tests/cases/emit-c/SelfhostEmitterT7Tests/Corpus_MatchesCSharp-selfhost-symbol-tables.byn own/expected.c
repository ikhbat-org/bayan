false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_sym bynh_chk_set_sym bynh_chk_move_sym bynh_chk_ret_sym
false bynh_chk_claim_sym bynh_chk_set_sym bynh_chk_move_sym bynh_chk_ret_sym
true bynh_chk_claim_list_map_sym_i32 bynh_chk_set_list_map_sym_i32 bynh_chk_move_list_map_sym_i32 bynh_chk_ret_list_map_sym_i32
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
true bynh_chk_claim_map_sym_main__TokenKind bynh_chk_set_map_sym_main__TokenKind bynh_chk_move_map_sym_main__TokenKind bynh_chk_ret_map_sym_main__TokenKind
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
true bynh_chk_claim_list_sym bynh_chk_set_list_sym bynh_chk_move_list_sym bynh_chk_ret_list_sym
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
true bynh_chk_claim_list_map_sym_i32 bynh_chk_set_list_map_sym_i32 bynh_chk_move_list_map_sym_i32 bynh_chk_ret_list_map_sym_i32
true bynh_chk_claim_map_tup2_i32_sym_i32 bynh_chk_set_map_tup2_i32_sym_i32 bynh_chk_move_map_tup2_i32_sym_i32 bynh_chk_ret_map_tup2_i32_sym_i32
true bynh_chk_claim_map_main__MemberKey_main__TokenKind bynh_chk_set_map_main__MemberKey_main__TokenKind bynh_chk_move_map_main__MemberKey_main__TokenKind bynh_chk_ret_map_main__MemberKey_main__TokenKind
true bynh_chk_claim_list_sym bynh_chk_set_list_sym bynh_chk_move_list_sym bynh_chk_ret_list_sym
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
true bynh_chk_claim_strbuf bynh_chk_set_strbuf bynh_chk_move_strbuf bynh_chk_ret_strbuf
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
helper bynh_chk_claim_list_map_sym_i32
static void bynh_chk_claim_list_map_sym_i32(bynt_list_map_sym_i32* p, const char* file, int line) {
    byn_own_claim((*p).ptr, &(*p), "List<Map<Symbol, i32>>", file, line);
}
helper bynh_chk_set_list_map_sym_i32
static bynt_list_map_sym_i32 bynh_chk_set_list_map_sym_i32(bynt_list_map_sym_i32* p, bynt_list_map_sym_i32 v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).ptr, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_list_map_sym_i32(p, file, line);
    return v;
}
helper bynh_chk_move_list_map_sym_i32
static bynt_list_map_sym_i32* bynh_chk_move_list_map_sym_i32(bynt_list_map_sym_i32* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "List<Map<Symbol, i32>>", file, line);
    byn_own_release((*p).ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_list_map_sym_i32
static bynt_list_map_sym_i32 bynh_chk_ret_list_map_sym_i32(bynt_list_map_sym_i32 v) {
    byn_own_release(v.ptr);
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
helper bynh_chk_claim_map_sym_main__TokenKind
static void bynh_chk_claim_map_sym_main__TokenKind(bynt_map_sym_main__TokenKind* p, const char* file, int line) {
    byn_own_claim((*p).keys, &(*p), "Map<Symbol, TokenKind>", file, line);
}
helper bynh_chk_set_map_sym_main__TokenKind
static bynt_map_sym_main__TokenKind bynh_chk_set_map_sym_main__TokenKind(bynt_map_sym_main__TokenKind* p, bynt_map_sym_main__TokenKind v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).keys, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_map_sym_main__TokenKind(p, file, line);
    return v;
}
helper bynh_chk_move_map_sym_main__TokenKind
static bynt_map_sym_main__TokenKind* bynh_chk_move_map_sym_main__TokenKind(bynt_map_sym_main__TokenKind* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Map<Symbol, TokenKind>", file, line);
    byn_own_release((*p).keys);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_map_sym_main__TokenKind
static bynt_map_sym_main__TokenKind bynh_chk_ret_map_sym_main__TokenKind(bynt_map_sym_main__TokenKind v) {
    byn_own_release(v.keys);
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
helper bynh_chk_claim_map_tup2_i32_sym_i32
static void bynh_chk_claim_map_tup2_i32_sym_i32(bynt_map_tup2_i32_sym_i32* p, const char* file, int line) {
    byn_own_claim((*p).keys, &(*p), "Map<(i32 scope, Symbol name), i32>", file, line);
}
helper bynh_chk_set_map_tup2_i32_sym_i32
static bynt_map_tup2_i32_sym_i32 bynh_chk_set_map_tup2_i32_sym_i32(bynt_map_tup2_i32_sym_i32* p, bynt_map_tup2_i32_sym_i32 v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).keys, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_map_tup2_i32_sym_i32(p, file, line);
    return v;
}
helper bynh_chk_move_map_tup2_i32_sym_i32
static bynt_map_tup2_i32_sym_i32* bynh_chk_move_map_tup2_i32_sym_i32(bynt_map_tup2_i32_sym_i32* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Map<(i32 scope, Symbol name), i32>", file, line);
    byn_own_release((*p).keys);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_map_tup2_i32_sym_i32
static bynt_map_tup2_i32_sym_i32 bynh_chk_ret_map_tup2_i32_sym_i32(bynt_map_tup2_i32_sym_i32 v) {
    byn_own_release(v.keys);
    return v;
}
helper bynh_chk_claim_map_main__MemberKey_main__TokenKind
static void bynh_chk_claim_map_main__MemberKey_main__TokenKind(bynt_map_main__MemberKey_main__TokenKind* p, const char* file, int line) {
    byn_own_claim((*p).keys, &(*p), "Map<MemberKey, TokenKind>", file, line);
}
helper bynh_chk_set_map_main__MemberKey_main__TokenKind
static bynt_map_main__MemberKey_main__TokenKind bynh_chk_set_map_main__MemberKey_main__TokenKind(bynt_map_main__MemberKey_main__TokenKind* p, bynt_map_main__MemberKey_main__TokenKind v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).keys, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_map_main__MemberKey_main__TokenKind(p, file, line);
    return v;
}
helper bynh_chk_move_map_main__MemberKey_main__TokenKind
static bynt_map_main__MemberKey_main__TokenKind* bynh_chk_move_map_main__MemberKey_main__TokenKind(bynt_map_main__MemberKey_main__TokenKind* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Map<MemberKey, TokenKind>", file, line);
    byn_own_release((*p).keys);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_map_main__MemberKey_main__TokenKind
static bynt_map_main__MemberKey_main__TokenKind bynh_chk_ret_map_main__MemberKey_main__TokenKind(bynt_map_main__MemberKey_main__TokenKind v) {
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