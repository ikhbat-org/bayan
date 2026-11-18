typedef struct bynt_map_i64_i64 bynt_map_i64_i64;
struct bynt_map_i64_i64 {
    byn_map_hdr h;
    int64_t* keys;
    int64_t* vals;
};