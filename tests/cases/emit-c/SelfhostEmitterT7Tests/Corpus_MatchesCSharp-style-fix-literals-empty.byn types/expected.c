typedef struct bynt_main__Bag bynt_main__Bag;
typedef struct bynt_list_i32 bynt_list_i32;
typedef struct bynt_map_str_i32 bynt_map_str_i32;
typedef struct bynt_main__Point bynt_main__Point;
struct bynt_list_i32 {
    int32_t* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_map_str_i32 {
    byn_map_hdr h;
    byn_str* keys;
    int32_t* vals;
};
struct bynt_main__Point {
    int32_t x;
    int32_t y;
};
struct bynt_main__Bag {
    bynt_list_i32 items;
    bynt_map_str_i32 counts;
    bynt_main__Point origin;
};