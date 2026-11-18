false bynh_chk_claim_main__Color bynh_chk_set_main__Color bynh_chk_move_main__Color bynh_chk_ret_main__Color
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_main__Suit bynh_chk_set_main__Suit bynh_chk_move_main__Suit bynh_chk_ret_main__Suit
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_main__Color bynh_chk_set_main__Color bynh_chk_move_main__Color bynh_chk_ret_main__Color
false bynh_chk_claim_main__Color bynh_chk_set_main__Color bynh_chk_move_main__Color bynh_chk_ret_main__Color
false bynh_chk_claim_opt_main__Color bynh_chk_set_opt_main__Color bynh_chk_move_opt_main__Color bynh_chk_ret_opt_main__Color
false bynh_chk_claim_opt_main__Color bynh_chk_set_opt_main__Color bynh_chk_move_opt_main__Color bynh_chk_ret_opt_main__Color
false bynh_chk_claim_opt_main__Color bynh_chk_set_opt_main__Color bynh_chk_move_opt_main__Color bynh_chk_ret_opt_main__Color
false bynh_chk_claim_main__Suit bynh_chk_set_main__Suit bynh_chk_move_main__Suit bynh_chk_ret_main__Suit
false bynh_chk_claim_main__Card bynh_chk_set_main__Card bynh_chk_move_main__Card bynh_chk_ret_main__Card
true bynh_chk_claim_list_main__Suit bynh_chk_set_list_main__Suit bynh_chk_move_list_main__Suit bynh_chk_ret_list_main__Suit
false bynh_chk_claim_opt_main__Suit bynh_chk_set_opt_main__Suit bynh_chk_move_opt_main__Suit bynh_chk_ret_opt_main__Suit
false bynh_chk_claim_opt_main__Suit bynh_chk_set_opt_main__Suit bynh_chk_move_opt_main__Suit bynh_chk_ret_opt_main__Suit
true bynh_chk_claim_strbuf bynh_chk_set_strbuf bynh_chk_move_strbuf bynh_chk_ret_strbuf
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
helper bynh_chk_claim_main__Color
static void bynh_chk_claim_main__Color(byn_main_Color* p, const char* file, int line) {
}
helper bynh_chk_set_main__Color
static byn_main_Color bynh_chk_set_main__Color(byn_main_Color* p, byn_main_Color v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Color(p, file, line);
    return v;
}
helper bynh_chk_move_main__Color
static byn_main_Color* bynh_chk_move_main__Color(byn_main_Color* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Color", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Color
static byn_main_Color bynh_chk_ret_main__Color(byn_main_Color v) {
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
helper bynh_chk_claim_main__Suit
static void bynh_chk_claim_main__Suit(byn_main_Suit* p, const char* file, int line) {
}
helper bynh_chk_set_main__Suit
static byn_main_Suit bynh_chk_set_main__Suit(byn_main_Suit* p, byn_main_Suit v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Suit(p, file, line);
    return v;
}
helper bynh_chk_move_main__Suit
static byn_main_Suit* bynh_chk_move_main__Suit(byn_main_Suit* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Suit", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Suit
static byn_main_Suit bynh_chk_ret_main__Suit(byn_main_Suit v) {
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
helper bynh_chk_claim_opt_main__Color
static void bynh_chk_claim_opt_main__Color(bynt_opt_main__Color* p, const char* file, int line) {
}
helper bynh_chk_set_opt_main__Color
static bynt_opt_main__Color bynh_chk_set_opt_main__Color(bynt_opt_main__Color* p, bynt_opt_main__Color v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_opt_main__Color(p, file, line);
    return v;
}
helper bynh_chk_move_opt_main__Color
static bynt_opt_main__Color* bynh_chk_move_opt_main__Color(bynt_opt_main__Color* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Color\077", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_opt_main__Color
static bynt_opt_main__Color bynh_chk_ret_opt_main__Color(bynt_opt_main__Color v) {
    return v;
}
helper bynh_chk_claim_main__Card
static void bynh_chk_claim_main__Card(bynt_main__Card* p, const char* file, int line) {
}
helper bynh_chk_set_main__Card
static bynt_main__Card bynh_chk_set_main__Card(bynt_main__Card* p, bynt_main__Card v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Card(p, file, line);
    return v;
}
helper bynh_chk_move_main__Card
static bynt_main__Card* bynh_chk_move_main__Card(bynt_main__Card* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Card", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Card
static bynt_main__Card bynh_chk_ret_main__Card(bynt_main__Card v) {
    return v;
}
helper bynh_chk_claim_list_main__Suit
static void bynh_chk_claim_list_main__Suit(bynt_list_main__Suit* p, const char* file, int line) {
    byn_own_claim((*p).ptr, &(*p), "List<Suit>", file, line);
}
helper bynh_chk_set_list_main__Suit
static bynt_list_main__Suit bynh_chk_set_list_main__Suit(bynt_list_main__Suit* p, bynt_list_main__Suit v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).ptr, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_list_main__Suit(p, file, line);
    return v;
}
helper bynh_chk_move_list_main__Suit
static bynt_list_main__Suit* bynh_chk_move_list_main__Suit(bynt_list_main__Suit* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "List<Suit>", file, line);
    byn_own_release((*p).ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_list_main__Suit
static bynt_list_main__Suit bynh_chk_ret_list_main__Suit(bynt_list_main__Suit v) {
    byn_own_release(v.ptr);
    return v;
}
helper bynh_chk_claim_opt_main__Suit
static void bynh_chk_claim_opt_main__Suit(bynt_opt_main__Suit* p, const char* file, int line) {
}
helper bynh_chk_set_opt_main__Suit
static bynt_opt_main__Suit bynh_chk_set_opt_main__Suit(bynt_opt_main__Suit* p, bynt_opt_main__Suit v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_opt_main__Suit(p, file, line);
    return v;
}
helper bynh_chk_move_opt_main__Suit
static bynt_opt_main__Suit* bynh_chk_move_opt_main__Suit(bynt_opt_main__Suit* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Suit\077", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_opt_main__Suit
static bynt_opt_main__Suit bynh_chk_ret_opt_main__Suit(bynt_opt_main__Suit v) {
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