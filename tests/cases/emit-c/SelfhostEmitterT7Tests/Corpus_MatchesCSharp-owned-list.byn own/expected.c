false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_opt_own_main__Node bynh_chk_set_opt_own_main__Node bynh_chk_move_opt_own_main__Node bynh_chk_ret_opt_own_main__Node
false bynh_chk_claim_opt_own_main__Node bynh_chk_set_opt_own_main__Node bynh_chk_move_opt_own_main__Node bynh_chk_ret_opt_own_main__Node
false bynh_chk_claim_opt_own_main__Node bynh_chk_set_opt_own_main__Node bynh_chk_move_opt_own_main__Node bynh_chk_ret_opt_own_main__Node
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
true bynh_chk_claim_main__Tree bynh_chk_set_main__Tree bynh_chk_move_main__Tree bynh_chk_ret_main__Tree
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_arena bynh_chk_set_arena bynh_chk_move_arena bynh_chk_ret_arena
true bynh_chk_claim_strbuf bynh_chk_set_strbuf bynh_chk_move_strbuf bynh_chk_ret_strbuf
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
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
helper bynh_chk_claim_opt_own_main__Node
static void bynh_chk_claim_opt_own_main__Node(bynt_opt_own_main__Node* p, const char* file, int line) {
}
helper bynh_chk_set_opt_own_main__Node
static bynt_opt_own_main__Node bynh_chk_set_opt_own_main__Node(bynt_opt_own_main__Node* p, bynt_opt_own_main__Node v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_opt_own_main__Node(p, file, line);
    return v;
}
helper bynh_chk_move_opt_own_main__Node
static bynt_opt_own_main__Node* bynh_chk_move_opt_own_main__Node(bynt_opt_own_main__Node* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Owned<Node>\077", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_opt_own_main__Node
static bynt_opt_own_main__Node bynh_chk_ret_opt_own_main__Node(bynt_opt_own_main__Node v) {
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
helper bynh_chk_claim_main__Tree
static void bynh_chk_claim_main__Tree(bynt_main__Tree* p, const char* file, int line) {
    byn_own_claim((*p).children.ptr, &(*p).children, "List<Tree>", file, line);
}
helper bynh_chk_set_main__Tree
static bynt_main__Tree bynh_chk_set_main__Tree(bynt_main__Tree* p, bynt_main__Tree v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).children.ptr, &(*p).children);
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Tree(p, file, line);
    return v;
}
helper bynh_chk_move_main__Tree
static bynt_main__Tree* bynh_chk_move_main__Tree(bynt_main__Tree* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Tree", file, line);
    byn_own_release((*p).children.ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Tree
static bynt_main__Tree bynh_chk_ret_main__Tree(bynt_main__Tree v) {
    byn_own_release(v.children.ptr);
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
helper bynh_chk_claim_arena
static void bynh_chk_claim_arena(byn_arena** p, const char* file, int line) {
}
helper bynh_chk_set_arena
static byn_arena* bynh_chk_set_arena(byn_arena** p, byn_arena* v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_arena(p, file, line);
    return v;
}
helper bynh_chk_move_arena
static byn_arena** bynh_chk_move_arena(byn_arena** p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Arena", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_arena
static byn_arena* bynh_chk_ret_arena(byn_arena* v) {
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