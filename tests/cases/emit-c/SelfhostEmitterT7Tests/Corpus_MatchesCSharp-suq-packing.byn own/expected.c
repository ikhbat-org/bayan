false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_main__BoxSize bynh_chk_set_main__BoxSize bynh_chk_move_main__BoxSize bynh_chk_ret_main__BoxSize
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_span_main__PackItem bynh_chk_set_span_main__PackItem bynh_chk_move_span_main__PackItem bynh_chk_ret_span_main__PackItem
false bynh_chk_claim_span_i32 bynh_chk_set_span_i32 bynh_chk_move_span_i32 bynh_chk_ret_span_i32
false bynh_chk_claim_span_main__PackedBox bynh_chk_set_span_main__PackedBox bynh_chk_move_span_main__PackedBox bynh_chk_ret_span_main__PackedBox
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_span_main__PackItem bynh_chk_set_span_main__PackItem bynh_chk_move_span_main__PackItem bynh_chk_ret_span_main__PackItem
false bynh_chk_claim_span_i32 bynh_chk_set_span_i32 bynh_chk_move_span_i32 bynh_chk_ret_span_i32
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_u8 bynh_chk_set_u8 bynh_chk_move_u8 bynh_chk_ret_u8
false bynh_chk_claim_u32 bynh_chk_set_u32 bynh_chk_move_u32 bynh_chk_ret_u32
false bynh_chk_claim_span_main__PackItem bynh_chk_set_span_main__PackItem bynh_chk_move_span_main__PackItem bynh_chk_ret_span_main__PackItem
false bynh_chk_claim_str bynh_chk_set_str bynh_chk_move_str bynh_chk_ret_str
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
false bynh_chk_claim_span_i32 bynh_chk_set_span_i32 bynh_chk_move_span_i32 bynh_chk_ret_span_i32
false bynh_chk_claim_span_main__PackedBox bynh_chk_set_span_main__PackedBox bynh_chk_move_span_main__PackedBox bynh_chk_ret_span_main__PackedBox
false bynh_chk_claim_i32 bynh_chk_set_i32 bynh_chk_move_i32 bynh_chk_ret_i32
false bynh_chk_claim_void bynh_chk_set_void bynh_chk_move_void bynh_chk_ret_void
true bynh_chk_claim_list_main__PackItem bynh_chk_set_list_main__PackItem bynh_chk_move_list_main__PackItem bynh_chk_ret_list_main__PackItem
true bynh_chk_claim_list_main__PackItem bynh_chk_set_list_main__PackItem bynh_chk_move_list_main__PackItem bynh_chk_ret_list_main__PackItem
true bynh_chk_claim_list_main__PackItem bynh_chk_set_list_main__PackItem bynh_chk_move_list_main__PackItem bynh_chk_ret_list_main__PackItem
false bynh_chk_claim_span_i32 bynh_chk_set_span_i32 bynh_chk_move_span_i32 bynh_chk_ret_span_i32
true bynh_chk_claim_strbuf bynh_chk_set_strbuf bynh_chk_move_strbuf bynh_chk_ret_strbuf
false bynh_chk_claim_u16 bynh_chk_set_u16 bynh_chk_move_u16 bynh_chk_ret_u16
false bynh_chk_claim_u32 bynh_chk_set_u32 bynh_chk_move_u32 bynh_chk_ret_u32
false bynh_chk_claim_i64 bynh_chk_set_i64 bynh_chk_move_i64 bynh_chk_ret_i64
false bynh_chk_claim_main__PackItem bynh_chk_set_main__PackItem bynh_chk_move_main__PackItem bynh_chk_ret_main__PackItem
false bynh_chk_claim_bool bynh_chk_set_bool bynh_chk_move_bool bynh_chk_ret_bool
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
helper bynh_chk_claim_main__BoxSize
static void bynh_chk_claim_main__BoxSize(bynt_main__BoxSize* p, const char* file, int line) {
}
helper bynh_chk_set_main__BoxSize
static bynt_main__BoxSize bynh_chk_set_main__BoxSize(bynt_main__BoxSize* p, bynt_main__BoxSize v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__BoxSize(p, file, line);
    return v;
}
helper bynh_chk_move_main__BoxSize
static bynt_main__BoxSize* bynh_chk_move_main__BoxSize(bynt_main__BoxSize* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "BoxSize", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__BoxSize
static bynt_main__BoxSize bynh_chk_ret_main__BoxSize(bynt_main__BoxSize v) {
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
helper bynh_chk_claim_span_main__PackItem
static void bynh_chk_claim_span_main__PackItem(bynt_span_main__PackItem* p, const char* file, int line) {
}
helper bynh_chk_set_span_main__PackItem
static bynt_span_main__PackItem bynh_chk_set_span_main__PackItem(bynt_span_main__PackItem* p, bynt_span_main__PackItem v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_span_main__PackItem(p, file, line);
    return v;
}
helper bynh_chk_move_span_main__PackItem
static bynt_span_main__PackItem* bynh_chk_move_span_main__PackItem(bynt_span_main__PackItem* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "ReadOnlySpan<PackItem>", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_span_main__PackItem
static bynt_span_main__PackItem bynh_chk_ret_span_main__PackItem(bynt_span_main__PackItem v) {
    return v;
}
helper bynh_chk_claim_span_i32
static void bynh_chk_claim_span_i32(bynt_span_i32* p, const char* file, int line) {
}
helper bynh_chk_set_span_i32
static bynt_span_i32 bynh_chk_set_span_i32(bynt_span_i32* p, bynt_span_i32 v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_span_i32(p, file, line);
    return v;
}
helper bynh_chk_move_span_i32
static bynt_span_i32* bynh_chk_move_span_i32(bynt_span_i32* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Span<i32>", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_span_i32
static bynt_span_i32 bynh_chk_ret_span_i32(bynt_span_i32 v) {
    return v;
}
helper bynh_chk_claim_span_main__PackedBox
static void bynh_chk_claim_span_main__PackedBox(bynt_span_main__PackedBox* p, const char* file, int line) {
}
helper bynh_chk_set_span_main__PackedBox
static bynt_span_main__PackedBox bynh_chk_set_span_main__PackedBox(bynt_span_main__PackedBox* p, bynt_span_main__PackedBox v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_span_main__PackedBox(p, file, line);
    return v;
}
helper bynh_chk_move_span_main__PackedBox
static bynt_span_main__PackedBox* bynh_chk_move_span_main__PackedBox(bynt_span_main__PackedBox* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "Span<PackedBox>", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_span_main__PackedBox
static bynt_span_main__PackedBox bynh_chk_ret_span_main__PackedBox(bynt_span_main__PackedBox v) {
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
helper bynh_chk_claim_u8
static void bynh_chk_claim_u8(uint8_t* p, const char* file, int line) {
}
helper bynh_chk_set_u8
static uint8_t bynh_chk_set_u8(uint8_t* p, uint8_t v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_u8(p, file, line);
    return v;
}
helper bynh_chk_move_u8
static uint8_t* bynh_chk_move_u8(uint8_t* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "u8", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_u8
static uint8_t bynh_chk_ret_u8(uint8_t v) {
    return v;
}
helper bynh_chk_claim_u32
static void bynh_chk_claim_u32(uint32_t* p, const char* file, int line) {
}
helper bynh_chk_set_u32
static uint32_t bynh_chk_set_u32(uint32_t* p, uint32_t v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_u32(p, file, line);
    return v;
}
helper bynh_chk_move_u32
static uint32_t* bynh_chk_move_u32(uint32_t* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "u32", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_u32
static uint32_t bynh_chk_ret_u32(uint32_t v) {
    return v;
}
helper bynh_chk_claim_list_main__PackItem
static void bynh_chk_claim_list_main__PackItem(bynt_list_main__PackItem* p, const char* file, int line) {
    byn_own_claim((*p).ptr, &(*p), "List<PackItem>", file, line);
}
helper bynh_chk_set_list_main__PackItem
static bynt_list_main__PackItem bynh_chk_set_list_main__PackItem(bynt_list_main__PackItem* p, bynt_list_main__PackItem v, byn_own_slot* s, bool claim, const char* file, int line) {
    byn_own_drop((*p).ptr, &(*p));
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_list_main__PackItem(p, file, line);
    return v;
}
helper bynh_chk_move_list_main__PackItem
static bynt_list_main__PackItem* bynh_chk_move_list_main__PackItem(bynt_list_main__PackItem* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "List<PackItem>", file, line);
    byn_own_release((*p).ptr);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_list_main__PackItem
static bynt_list_main__PackItem bynh_chk_ret_list_main__PackItem(bynt_list_main__PackItem v) {
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
helper bynh_chk_claim_u16
static void bynh_chk_claim_u16(uint16_t* p, const char* file, int line) {
}
helper bynh_chk_set_u16
static uint16_t bynh_chk_set_u16(uint16_t* p, uint16_t v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_u16(p, file, line);
    return v;
}
helper bynh_chk_move_u16
static uint16_t* bynh_chk_move_u16(uint16_t* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "u16", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_u16
static uint16_t bynh_chk_ret_u16(uint16_t v) {
    return v;
}
helper bynh_chk_claim_main__PackItem
static void bynh_chk_claim_main__PackItem(bynt_main__PackItem* p, const char* file, int line) {
}
helper bynh_chk_set_main__PackItem
static bynt_main__PackItem bynh_chk_set_main__PackItem(bynt_main__PackItem* p, bynt_main__PackItem v, byn_own_slot* s, bool claim, const char* file, int line) {
    *p = v;
    if (s) s->line = 0;
    if (claim) bynh_chk_claim_main__PackItem(p, file, line);
    return v;
}
helper bynh_chk_move_main__PackItem
static bynt_main__PackItem* bynh_chk_move_main__PackItem(bynt_main__PackItem* p, byn_own_slot* s, const char* file, int line) {
    if (s) byn_own_read(s, "PackItem", file, line);
    if (s) {
        s->file = file;
        s->line = line;
    }
    return p;
}
helper bynh_chk_ret_main__PackItem
static bynt_main__PackItem bynh_chk_ret_main__PackItem(bynt_main__PackItem v) {
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