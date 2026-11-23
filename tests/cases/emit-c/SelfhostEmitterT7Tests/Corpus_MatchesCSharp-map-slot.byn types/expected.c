typedef struct bynt_map_str_i64 bynt_map_str_i64;
typedef struct bynt_arr7_str bynt_arr7_str;
typedef struct bynt_map_rune_main__Tally bynt_map_rune_main__Tally;
typedef struct bynt_main__Tally bynt_main__Tally;
struct bynt_map_str_i64 {
    byn_map_hdr h;
    byn_str* keys;
    int64_t* vals;
};
struct bynt_arr7_str {
    byn_str v[7];
};
struct bynt_map_rune_main__Tally {
    byn_map_hdr h;
    uint32_t* keys;
    bynt_main__Tally* vals;
};
struct bynt_main__Tally {
    int64_t hits;
    byn_str note;
};