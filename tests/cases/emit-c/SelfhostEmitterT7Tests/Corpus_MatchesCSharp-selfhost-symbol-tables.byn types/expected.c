typedef struct bynt_list_map_sym_i32 bynt_list_map_sym_i32;
typedef struct bynt_map_sym_main__TokenKind bynt_map_sym_main__TokenKind;
typedef struct bynt_list_sym bynt_list_sym;
typedef struct bynt_map_tup2_i32_sym_i32 bynt_map_tup2_i32_sym_i32;
typedef struct bynt_map_main__MemberKey_main__TokenKind bynt_map_main__MemberKey_main__TokenKind;
typedef struct bynt_map_sym_i32 bynt_map_sym_i32;
typedef struct bynt_tup2_i32_sym bynt_tup2_i32_sym;
typedef struct bynt_main__MemberKey bynt_main__MemberKey;
struct bynt_list_map_sym_i32 {
    bynt_map_sym_i32* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_map_sym_main__TokenKind {
    byn_map_hdr h;
    byn_sym* keys;
    byn_main_TokenKind* vals;
};
struct bynt_list_sym {
    byn_sym* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_map_tup2_i32_sym_i32 {
    byn_map_hdr h;
    bynt_tup2_i32_sym* keys;
    int32_t* vals;
};
struct bynt_map_main__MemberKey_main__TokenKind {
    byn_map_hdr h;
    bynt_main__MemberKey* keys;
    byn_main_TokenKind* vals;
};
struct bynt_map_sym_i32 {
    byn_map_hdr h;
    byn_sym* keys;
    int32_t* vals;
};
struct bynt_tup2_i32_sym {
    int32_t item1;
    byn_sym item2;
};
struct bynt_main__MemberKey {
    int32_t owner;
    byn_sym name;
};