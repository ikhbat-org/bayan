typedef struct bynt_map_str_opt_i64 bynt_map_str_opt_i64;
typedef struct bynt_opt_i64 bynt_opt_i64;
struct bynt_map_str_opt_i64 {
    byn_map_hdr h;
    byn_str* keys;
    bynt_opt_i64* vals;
};
struct bynt_opt_i64 {
    bool has;
    int64_t value;
};