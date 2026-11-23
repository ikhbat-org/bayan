true bynh_chk_claim_map_str_i64 bynh_chk_set_map_str_i64 bynh_chk_move_map_str_i64 bynh_chk_ret_map_str_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
true bynh_chk_claim_list_i64 bynh_chk_set_list_i64 bynh_chk_move_list_i64 bynh_chk_ret_list_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
true bynh_chk_claim_strbuf bynh_chk_set_strbuf bynh_chk_move_strbuf bynh_chk_ret_strbuf
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_opt_i64 bynh_chk_set_opt_i64 bynh_chk_move_opt_i64 bynh_chk_ret_opt_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_main__E bynh_chk_set_main__E bynh_chk_move_main__E bynh_chk_ret_main__E
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_tup2_i64_bool bynh_chk_set_tup2_i64_bool bynh_chk_move_tup2_i64_bool bynh_chk_ret_tup2_i64_bool
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_fn1_i64_i64 bynh_chk_set_fn1_i64_i64 bynh_chk_move_fn1_i64_i64 bynh_chk_ret_fn1_i64_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_dyn_main__IBox bynh_chk_set_dyn_main__IBox bynh_chk_move_dyn_main__IBox bynh_chk_ret_dyn_main__IBox
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
true bynh_chk_claim_own_main__Pt bynh_chk_set_own_main__Pt bynh_chk_move_own_main__Pt bynh_chk_ret_own_main__Pt
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
true bynh_chk_claim_list_main__Pt bynh_chk_set_list_main__Pt bynh_chk_move_list_main__Pt bynh_chk_ret_list_main__Pt
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_main__Pt bynh_chk_set_main__Pt bynh_chk_move_main__Pt bynh_chk_ret_main__Pt
false bynh_chk_claim_opt_main__Pt bynh_chk_set_opt_main__Pt bynh_chk_move_opt_main__Pt bynh_chk_ret_opt_main__Pt
false bynh_chk_claim_res_i64 bynh_chk_set_res_i64 bynh_chk_move_res_i64 bynh_chk_ret_res_i64
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_arr3_i64 bynh_chk_set_arr3_i64 bynh_chk_move_arr3_i64 bynh_chk_ret_arr3_i64
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_span_i64 bynh_chk_set_span_i64 bynh_chk_move_span_i64 bynh_chk_ret_span_i64
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
true bynh_chk_claim_tup2_list_i64_map_str_i64 bynh_chk_set_tup2_list_i64_map_str_i64 bynh_chk_move_tup2_list_i64_map_str_i64 bynh_chk_ret_tup2_list_i64_map_str_i64
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
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
helper bynh_chk_claim_opt_i64
static void bynh_chk_claim_opt_i64(bynt_opt_i64* p, const char* file, int line) {
}
helper bynh_chk_set_opt_i64
static bynt_opt_i64 bynh_chk_set_opt_i64(bynt_opt_i64* p, bynt_opt_i64 v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_opt_i64(p, file, line);
    return v;
}
helper bynh_chk_move_opt_i64
static bynt_opt_i64* bynh_chk_move_opt_i64(bynt_opt_i64* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "i64\077", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_opt_i64
static bynt_opt_i64 bynh_chk_ret_opt_i64(bynt_opt_i64 v) {
    return v;
}
helper bynh_chk_claim_main__E
static void bynh_chk_claim_main__E(bynt_main__E* p, const char* file, int line) {
}
helper bynh_chk_set_main__E
static bynt_main__E bynh_chk_set_main__E(bynt_main__E* p, bynt_main__E v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__E(p, file, line);
    return v;
}
helper bynh_chk_move_main__E
static bynt_main__E* bynh_chk_move_main__E(bynt_main__E* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "E", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__E
static bynt_main__E bynh_chk_ret_main__E(bynt_main__E v) {
    return v;
}
helper bynh_chk_claim_tup2_i64_bool
static void bynh_chk_claim_tup2_i64_bool(bynt_tup2_i64_bool* p, const char* file, int line) {
}
helper bynh_chk_set_tup2_i64_bool
static bynt_tup2_i64_bool bynh_chk_set_tup2_i64_bool(bynt_tup2_i64_bool* p, bynt_tup2_i64_bool v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_tup2_i64_bool(p, file, line);
    return v;
}
helper bynh_chk_move_tup2_i64_bool
static bynt_tup2_i64_bool* bynh_chk_move_tup2_i64_bool(bynt_tup2_i64_bool* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "(i64, bool)", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_tup2_i64_bool
static bynt_tup2_i64_bool bynh_chk_ret_tup2_i64_bool(bynt_tup2_i64_bool v) {
    return v;
}
helper bynh_chk_claim_fn1_i64_i64
static void bynh_chk_claim_fn1_i64_i64(bynt_fn1_i64_i64* p, const char* file, int line) {
}
helper bynh_chk_set_fn1_i64_i64
static bynt_fn1_i64_i64 bynh_chk_set_fn1_i64_i64(bynt_fn1_i64_i64* p, bynt_fn1_i64_i64 v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_fn1_i64_i64(p, file, line);
    return v;
}
helper bynh_chk_move_fn1_i64_i64
static bynt_fn1_i64_i64* bynh_chk_move_fn1_i64_i64(bynt_fn1_i64_i64* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "i64 -> i64", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_fn1_i64_i64
static bynt_fn1_i64_i64 bynh_chk_ret_fn1_i64_i64(bynt_fn1_i64_i64 v) {
    return v;
}
helper bynh_chk_claim_dyn_main__IBox
static void bynh_chk_claim_dyn_main__IBox(byn_dyn_main__IBox* p, const char* file, int line) {
}
helper bynh_chk_set_dyn_main__IBox
static byn_dyn_main__IBox bynh_chk_set_dyn_main__IBox(byn_dyn_main__IBox* p, byn_dyn_main__IBox v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_dyn_main__IBox(p, file, line);
    return v;
}
helper bynh_chk_move_dyn_main__IBox
static byn_dyn_main__IBox* bynh_chk_move_dyn_main__IBox(byn_dyn_main__IBox* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "dyn ref IBox", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_dyn_main__IBox
static byn_dyn_main__IBox bynh_chk_ret_dyn_main__IBox(byn_dyn_main__IBox v) {
    return v;
}
helper bynh_chk_claim_own_main__Pt
static void bynh_chk_claim_own_main__Pt(bynt_main__Pt** p, const char* file, int line) {
    byn_own_claim((*p), &(*p), "Owned<Pt>", file, line);
}
helper bynh_chk_set_own_main__Pt
static bynt_main__Pt* bynh_chk_set_own_main__Pt(bynt_main__Pt** p, bynt_main__Pt* v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p), &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_own_main__Pt(p, file, line);
    return v;
}
helper bynh_chk_move_own_main__Pt
static bynt_main__Pt** bynh_chk_move_own_main__Pt(bynt_main__Pt** p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Owned<Pt>", file, line);
    byn_own_release((*p));
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_own_main__Pt
static bynt_main__Pt* bynh_chk_ret_own_main__Pt(bynt_main__Pt* v) {
    byn_own_release(v);
    return v;
}
helper bynh_chk_claim_list_main__Pt
static void bynh_chk_claim_list_main__Pt(bynt_list_main__Pt* p, const char* file, int line) {
    byn_own_claim((*p).ptr, &(*p), "List<Pt>", file, line);
}
helper bynh_chk_set_list_main__Pt
static bynt_list_main__Pt bynh_chk_set_list_main__Pt(bynt_list_main__Pt* p, bynt_list_main__Pt v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).ptr, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_list_main__Pt(p, file, line);
    return v;
}
helper bynh_chk_move_list_main__Pt
static bynt_list_main__Pt* bynh_chk_move_list_main__Pt(bynt_list_main__Pt* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "List<Pt>", file, line);
    byn_own_release((*p).ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_list_main__Pt
static bynt_list_main__Pt bynh_chk_ret_list_main__Pt(bynt_list_main__Pt v) {
    byn_own_release(v.ptr);
    return v;
}
helper bynh_chk_claim_main__Pt
static void bynh_chk_claim_main__Pt(bynt_main__Pt* p, const char* file, int line) {
}
helper bynh_chk_set_main__Pt
static bynt_main__Pt bynh_chk_set_main__Pt(bynt_main__Pt* p, bynt_main__Pt v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__Pt(p, file, line);
    return v;
}
helper bynh_chk_move_main__Pt
static bynt_main__Pt* bynh_chk_move_main__Pt(bynt_main__Pt* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Pt", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__Pt
static bynt_main__Pt bynh_chk_ret_main__Pt(bynt_main__Pt v) {
    return v;
}
helper bynh_chk_claim_opt_main__Pt
static void bynh_chk_claim_opt_main__Pt(bynt_opt_main__Pt* p, const char* file, int line) {
}
helper bynh_chk_set_opt_main__Pt
static bynt_opt_main__Pt bynh_chk_set_opt_main__Pt(bynt_opt_main__Pt* p, bynt_opt_main__Pt v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_opt_main__Pt(p, file, line);
    return v;
}
helper bynh_chk_move_opt_main__Pt
static bynt_opt_main__Pt* bynh_chk_move_opt_main__Pt(bynt_opt_main__Pt* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Pt\077", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_opt_main__Pt
static bynt_opt_main__Pt bynh_chk_ret_opt_main__Pt(bynt_opt_main__Pt v) {
    return v;
}
helper bynh_chk_claim_res_i64
static void bynh_chk_claim_res_i64(bynt_res_i64* p, const char* file, int line) {
}
helper bynh_chk_set_res_i64
static bynt_res_i64 bynh_chk_set_res_i64(bynt_res_i64* p, bynt_res_i64 v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_res_i64(p, file, line);
    return v;
}
helper bynh_chk_move_res_i64
static bynt_res_i64* bynh_chk_move_res_i64(bynt_res_i64* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Result<i64, Bad>", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_res_i64
static bynt_res_i64 bynh_chk_ret_res_i64(bynt_res_i64 v) {
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
helper bynh_chk_claim_arr3_i64
static void bynh_chk_claim_arr3_i64(bynt_arr3_i64* p, const char* file, int line) {
}
helper bynh_chk_set_arr3_i64
static bynt_arr3_i64 bynh_chk_set_arr3_i64(bynt_arr3_i64* p, bynt_arr3_i64 v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_arr3_i64(p, file, line);
    return v;
}
helper bynh_chk_move_arr3_i64
static bynt_arr3_i64* bynh_chk_move_arr3_i64(bynt_arr3_i64* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "i64[3]", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_arr3_i64
static bynt_arr3_i64 bynh_chk_ret_arr3_i64(bynt_arr3_i64 v) {
    return v;
}
helper bynh_chk_claim_span_i64
static void bynh_chk_claim_span_i64(bynt_span_i64* p, const char* file, int line) {
}
helper bynh_chk_set_span_i64
static bynt_span_i64 bynh_chk_set_span_i64(bynt_span_i64* p, bynt_span_i64 v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_span_i64(p, file, line);
    return v;
}
helper bynh_chk_move_span_i64
static bynt_span_i64* bynh_chk_move_span_i64(bynt_span_i64* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Span<i64>", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_span_i64
static bynt_span_i64 bynh_chk_ret_span_i64(bynt_span_i64 v) {
    return v;
}
helper bynh_chk_claim_tup2_list_i64_map_str_i64
static void bynh_chk_claim_tup2_list_i64_map_str_i64(bynt_tup2_list_i64_map_str_i64* p, const char* file, int line) {
    byn_own_claim((*p).item1.ptr, &(*p).item1, "List<i64>", file, line);
    byn_own_claim((*p).item2.keys, &(*p).item2, "Map<string, i64>", file, line);
}
helper bynh_chk_set_tup2_list_i64_map_str_i64
static bynt_tup2_list_i64_map_str_i64 bynh_chk_set_tup2_list_i64_map_str_i64(bynt_tup2_list_i64_map_str_i64* p, bynt_tup2_list_i64_map_str_i64 v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).item1.ptr, &(*p).item1);
    byn_own_drop((*p).item2.keys, &(*p).item2);
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_tup2_list_i64_map_str_i64(p, file, line);
    return v;
}
helper bynh_chk_move_tup2_list_i64_map_str_i64
static bynt_tup2_list_i64_map_str_i64* bynh_chk_move_tup2_list_i64_map_str_i64(bynt_tup2_list_i64_map_str_i64* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "(List<i64>, Map<string, i64>)", file, line);
    byn_own_release((*p).item1.ptr);
    byn_own_release((*p).item2.keys);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_tup2_list_i64_map_str_i64
static bynt_tup2_list_i64_map_str_i64 bynh_chk_ret_tup2_list_i64_map_str_i64(bynt_tup2_list_i64_map_str_i64 v) {
    byn_own_release(v.item1.ptr);
    byn_own_release(v.item2.keys);
    return v;
}