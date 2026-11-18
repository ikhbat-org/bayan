false bynh_chk_claim_dyn_main__INode bynh_chk_set_dyn_main__INode bynh_chk_move_dyn_main__INode bynh_chk_ret_dyn_main__INode
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
true bynh_chk_claim_list_main__Token bynh_chk_set_list_main__Token bynh_chk_move_list_main__Token bynh_chk_ret_list_main__Token
true bynh_chk_claim_list_main__Token bynh_chk_set_list_main__Token bynh_chk_move_list_main__Token bynh_chk_ret_list_main__Token
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
true bynh_chk_claim_main__TokenList bynh_chk_set_main__TokenList bynh_chk_move_main__TokenList bynh_chk_ret_main__TokenList
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
true bynh_chk_claim_main__TokenStream bynh_chk_set_main__TokenStream bynh_chk_move_main__TokenStream bynh_chk_ret_main__TokenStream
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_main__Num bynh_chk_set_main__Num bynh_chk_move_main__Num bynh_chk_ret_main__Num
false bynh_chk_claim_main__Add bynh_chk_set_main__Add bynh_chk_move_main__Add bynh_chk_ret_main__Add
false bynh_chk_claim_main__Mul bynh_chk_set_main__Mul bynh_chk_move_main__Mul bynh_chk_ret_main__Mul
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_main__Token bynh_chk_set_main__Token bynh_chk_move_main__Token bynh_chk_ret_main__Token
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
false bynh_chk_claim_main__Token bynh_chk_set_main__Token bynh_chk_move_main__Token bynh_chk_ret_main__Token
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_main__Num bynh_chk_set_main__Num bynh_chk_move_main__Num bynh_chk_ret_main__Num
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_main__Add bynh_chk_set_main__Add bynh_chk_move_main__Add bynh_chk_ret_main__Add
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_main__Mul bynh_chk_set_main__Mul bynh_chk_move_main__Mul bynh_chk_ret_main__Mul
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
helper bynh_chk_claim_dyn_main__INode
static void bynh_chk_claim_dyn_main__INode(byn_dyn_main__INode* p, const char* file, int line) {
}
helper bynh_chk_set_dyn_main__INode
static byn_dyn_main__INode bynh_chk_set_dyn_main__INode(byn_dyn_main__INode* p, byn_dyn_main__INode v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_dyn_main__INode(p, file, line);
    return v;
}
helper bynh_chk_move_dyn_main__INode
static byn_dyn_main__INode* bynh_chk_move_dyn_main__INode(byn_dyn_main__INode* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "dyn ref readonly INode", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_dyn_main__INode
static byn_dyn_main__INode bynh_chk_ret_dyn_main__INode(byn_dyn_main__INode v) {
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
helper bynh_chk_claim_main__TokenList
static void bynh_chk_claim_main__TokenList(bynt_main__TokenList* p, const char* file, int line) {
    byn_own_claim((*p).tokens.ptr, &(*p).tokens, "List<Token>", file, line);
}
helper bynh_chk_set_main__TokenList
static bynt_main__TokenList bynh_chk_set_main__TokenList(bynt_main__TokenList* p, bynt_main__TokenList v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).tokens.ptr, &(*p).tokens);
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__TokenList(p, file, line);
    return v;
}
helper bynh_chk_move_main__TokenList
static bynt_main__TokenList* bynh_chk_move_main__TokenList(bynt_main__TokenList* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "TokenList", file, line);
    byn_own_release((*p).tokens.ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__TokenList
static bynt_main__TokenList bynh_chk_ret_main__TokenList(bynt_main__TokenList v) {
    byn_own_release(v.tokens.ptr);
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
helper bynh_chk_claim_main__TokenStream
static void bynh_chk_claim_main__TokenStream(bynt_main__TokenStream* p, const char* file, int line) {
    byn_own_claim((*p).tokens.ptr, &(*p).tokens, "List<Token>", file, line);
}
helper bynh_chk_set_main__TokenStream
static bynt_main__TokenStream bynh_chk_set_main__TokenStream(bynt_main__TokenStream* p, bynt_main__TokenStream v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).tokens.ptr, &(*p).tokens);
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__TokenStream(p, file, line);
    return v;
}
helper bynh_chk_move_main__TokenStream
static bynt_main__TokenStream* bynh_chk_move_main__TokenStream(bynt_main__TokenStream* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "TokenStream", file, line);
    byn_own_release((*p).tokens.ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__TokenStream
static bynt_main__TokenStream bynh_chk_ret_main__TokenStream(bynt_main__TokenStream v) {
    byn_own_release(v.tokens.ptr);
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
helper bynh_chk_claim_main__Num
static void bynh_chk_claim_main__Num(bynt_main__Num* p, const char* file, int line) {
}
helper bynh_chk_set_main__Num
static bynt_main__Num bynh_chk_set_main__Num(bynt_main__Num* p, bynt_main__Num v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Num(p, file, line);
    return v;
}
helper bynh_chk_move_main__Num
static bynt_main__Num* bynh_chk_move_main__Num(bynt_main__Num* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Num", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Num
static bynt_main__Num bynh_chk_ret_main__Num(bynt_main__Num v) {
    return v;
}
helper bynh_chk_claim_main__Add
static void bynh_chk_claim_main__Add(bynt_main__Add* p, const char* file, int line) {
}
helper bynh_chk_set_main__Add
static bynt_main__Add bynh_chk_set_main__Add(bynt_main__Add* p, bynt_main__Add v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Add(p, file, line);
    return v;
}
helper bynh_chk_move_main__Add
static bynt_main__Add* bynh_chk_move_main__Add(bynt_main__Add* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Add", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Add
static bynt_main__Add bynh_chk_ret_main__Add(bynt_main__Add v) {
    return v;
}
helper bynh_chk_claim_main__Mul
static void bynh_chk_claim_main__Mul(bynt_main__Mul* p, const char* file, int line) {
}
helper bynh_chk_set_main__Mul
static bynt_main__Mul bynh_chk_set_main__Mul(bynt_main__Mul* p, bynt_main__Mul v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Mul(p, file, line);
    return v;
}
helper bynh_chk_move_main__Mul
static bynt_main__Mul* bynh_chk_move_main__Mul(bynt_main__Mul* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Mul", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Mul
static bynt_main__Mul bynh_chk_ret_main__Mul(bynt_main__Mul v) {
    return v;
}
helper bynh_chk_claim_main__Token
static void bynh_chk_claim_main__Token(bynt_main__Token* p, const char* file, int line) {
}
helper bynh_chk_set_main__Token
static bynt_main__Token bynh_chk_set_main__Token(bynt_main__Token* p, bynt_main__Token v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Token(p, file, line);
    return v;
}
helper bynh_chk_move_main__Token
static bynt_main__Token* bynh_chk_move_main__Token(bynt_main__Token* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Token", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Token
static bynt_main__Token bynh_chk_ret_main__Token(bynt_main__Token v) {
    return v;
}
helper bynh_chk_claim_bool
static void bynh_chk_claim_bool(bool* p, const char* file, int line) {
}
helper bynh_chk_set_bool
static bool bynh_chk_set_bool(bool* p, bool v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_bool(p, file, line);
    return v;
}
helper bynh_chk_move_bool
static bool* bynh_chk_move_bool(bool* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "bool", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_bool
static bool bynh_chk_ret_bool(bool v) {
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