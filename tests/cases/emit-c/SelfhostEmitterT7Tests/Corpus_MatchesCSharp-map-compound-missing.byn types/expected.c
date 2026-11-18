typedef struct bynt_map_str_i64 bynt_map_str_i64;
struct bynt_map_str_i64 {
    byn_map_hdr h;
    byn_str* keys;
    int64_t* vals;
};