false bynh_chk_claim_main__Shape bynh_chk_set_main__Shape bynh_chk_move_main__Shape bynh_chk_ret_main__Shape
false bynh_chk_claim_f32 bynh_chk_set_f32 bynh_chk_move_f32 bynh_chk_ret_f32
false bynh_chk_claim_main__Shape bynh_chk_set_main__Shape bynh_chk_move_main__Shape bynh_chk_ret_main__Shape
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_f32 bynh_chk_set_f32 bynh_chk_move_f32 bynh_chk_ret_f32
false bynh_chk_claim_main__Shape bynh_chk_set_main__Shape bynh_chk_move_main__Shape bynh_chk_ret_main__Shape
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_main__Shape bynh_chk_set_main__Shape bynh_chk_move_main__Shape bynh_chk_ret_main__Shape
false bynh_chk_claim_main__Shape bynh_chk_set_main__Shape bynh_chk_move_main__Shape bynh_chk_ret_main__Shape
false bynh_chk_claim_main__Shape bynh_chk_set_main__Shape bynh_chk_move_main__Shape bynh_chk_ret_main__Shape
true bynh_chk_claim_list_main__Shape bynh_chk_set_list_main__Shape bynh_chk_move_list_main__Shape bynh_chk_ret_list_main__Shape
false bynh_chk_claim_f32 bynh_chk_set_f32 bynh_chk_move_f32 bynh_chk_ret_f32
false bynh_chk_claim_main__Slot bynh_chk_set_main__Slot bynh_chk_move_main__Slot bynh_chk_ret_main__Slot
false bynh_chk_claim_opt_main__Shape bynh_chk_set_opt_main__Shape bynh_chk_move_opt_main__Shape bynh_chk_ret_opt_main__Shape
false bynh_chk_claim_opt_main__Shape bynh_chk_set_opt_main__Shape bynh_chk_move_opt_main__Shape bynh_chk_ret_opt_main__Shape
true bynh_chk_claim_list_main__Token bynh_chk_set_list_main__Token bynh_chk_move_list_main__Token bynh_chk_ret_list_main__Token
true bynh_chk_claim_strbuf bynh_chk_set_strbuf bynh_chk_move_strbuf bynh_chk_ret_strbuf
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
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
helper bynh_chk_claim_f32
static void bynh_chk_claim_f32(float* p, const char* file, int line) {
}
helper bynh_chk_set_f32
static float bynh_chk_set_f32(float* p, float v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_f32(p, file, line);
    return v;
}
helper bynh_chk_move_f32
static float* bynh_chk_move_f32(float* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "f32", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_f32
static float bynh_chk_ret_f32(float v) {
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
helper bynh_chk_claim_list_main__Shape
static void bynh_chk_claim_list_main__Shape(bynt_list_main__Shape* p, const char* file, int line) {
    byn_own_claim((*p).ptr, &(*p), "List<Shape>", file, line);
}
helper bynh_chk_set_list_main__Shape
static bynt_list_main__Shape bynh_chk_set_list_main__Shape(bynt_list_main__Shape* p, bynt_list_main__Shape v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).ptr, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_list_main__Shape(p, file, line);
    return v;
}
helper bynh_chk_move_list_main__Shape
static bynt_list_main__Shape* bynh_chk_move_list_main__Shape(bynt_list_main__Shape* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "List<Shape>", file, line);
    byn_own_release((*p).ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_list_main__Shape
static bynt_list_main__Shape bynh_chk_ret_list_main__Shape(bynt_list_main__Shape v) {
    byn_own_release(v.ptr);
    return v;
}
helper bynh_chk_claim_main__Slot
static void bynh_chk_claim_main__Slot(bynt_main__Slot* p, const char* file, int line) {
}
helper bynh_chk_set_main__Slot
static bynt_main__Slot bynh_chk_set_main__Slot(bynt_main__Slot* p, bynt_main__Slot v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Slot(p, file, line);
    return v;
}
helper bynh_chk_move_main__Slot
static bynt_main__Slot* bynh_chk_move_main__Slot(bynt_main__Slot* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Slot", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Slot
static bynt_main__Slot bynh_chk_ret_main__Slot(bynt_main__Slot v) {
    return v;
}
helper bynh_chk_claim_opt_main__Shape
static void bynh_chk_claim_opt_main__Shape(bynt_opt_main__Shape* p, const char* file, int line) {
}
helper bynh_chk_set_opt_main__Shape
static bynt_opt_main__Shape bynh_chk_set_opt_main__Shape(bynt_opt_main__Shape* p, bynt_opt_main__Shape v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_opt_main__Shape(p, file, line);
    return v;
}
helper bynh_chk_move_opt_main__Shape
static bynt_opt_main__Shape* bynh_chk_move_opt_main__Shape(bynt_opt_main__Shape* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Shape\077", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_opt_main__Shape
static bynt_opt_main__Shape bynh_chk_ret_opt_main__Shape(bynt_opt_main__Shape v) {
    return v;
}
helper bynh_chk_claim_list_main__Token
static void bynh_chk_claim_list_main__Token(bynt_list_main__Token* p, const char* file, int line) {
    byn_own_claim((*p).ptr, &(*p), "List<Token>", file, line);
}
helper bynh_chk_set_list_main__Token
static bynt_list_main__Token bynh_chk_set_list_main__Token(bynt_list_main__Token* p, bynt_list_main__Token v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).ptr, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_list_main__Token(p, file, line);
    return v;
}
helper bynh_chk_move_list_main__Token
static bynt_list_main__Token* bynh_chk_move_list_main__Token(bynt_list_main__Token* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "List<Token>", file, line);
    byn_own_release((*p).ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_list_main__Token
static bynt_list_main__Token bynh_chk_ret_list_main__Token(bynt_list_main__Token v) {
    byn_own_release(v.ptr);
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