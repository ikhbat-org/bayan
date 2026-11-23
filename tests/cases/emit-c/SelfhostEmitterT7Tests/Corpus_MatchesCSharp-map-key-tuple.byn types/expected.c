typedef struct bynt_map_tup2_i32_sym_i32 bynt_map_tup2_i32_sym_i32;
typedef struct bynt_tup2_i32_sym bynt_tup2_i32_sym;
struct bynt_map_tup2_i32_sym_i32 {
    byn_map_hdr h;
    bynt_tup2_i32_sym* keys;
    int32_t* vals;
};
struct bynt_tup2_i32_sym {
    int32_t item1;
    byn_sym item2;
};