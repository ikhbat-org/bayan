typedef struct bynt_main__Inventory bynt_main__Inventory;
typedef struct bynt_map_str_i64 bynt_map_str_i64;
typedef struct bynt_map_main__Suit_i32 bynt_map_main__Suit_i32;
typedef struct bynt_arr6_main__Suit bynt_arr6_main__Suit;
typedef struct bynt_map_i64_i64 bynt_map_i64_i64;
typedef struct bynt_map_rune_bool bynt_map_rune_bool;
typedef struct bynt_map_bool_str bynt_map_bool_str;
struct bynt_map_str_i64 {
    byn_map_hdr h;
    byn_str* keys;
    int64_t* vals;
};
struct bynt_main__Inventory {
    byn_str owner;
    bynt_map_str_i64 stock;
};
struct bynt_map_main__Suit_i32 {
    byn_map_hdr h;
    byn_main_Suit* keys;
    int32_t* vals;
};
struct bynt_arr6_main__Suit {
    byn_main_Suit v[6];
};
struct bynt_map_i64_i64 {
    byn_map_hdr h;
    int64_t* keys;
    int64_t* vals;
};
struct bynt_map_rune_bool {
    byn_map_hdr h;
    uint32_t* keys;
    bool* vals;
};
struct bynt_map_bool_str {
    byn_map_hdr h;
    bool* keys;
    byn_str* vals;
};