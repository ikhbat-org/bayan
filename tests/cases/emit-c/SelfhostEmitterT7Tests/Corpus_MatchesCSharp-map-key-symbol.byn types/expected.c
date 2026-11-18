typedef struct bynt_map_sym_i32 bynt_map_sym_i32;
struct bynt_map_sym_i32 {
    byn_map_hdr h;
    byn_sym* keys;
    int32_t* vals;
};