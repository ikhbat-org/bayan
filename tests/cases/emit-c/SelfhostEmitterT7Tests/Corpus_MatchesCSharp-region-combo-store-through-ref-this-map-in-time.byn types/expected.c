typedef struct bynt_main__Bag bynt_main__Bag;
typedef struct bynt_map_i64_str bynt_map_i64_str;
struct bynt_map_i64_str {
    byn_map_hdr h;
    int64_t* keys;
    byn_str* vals;
};
struct bynt_main__Bag {
    bynt_map_i64_str m;
};