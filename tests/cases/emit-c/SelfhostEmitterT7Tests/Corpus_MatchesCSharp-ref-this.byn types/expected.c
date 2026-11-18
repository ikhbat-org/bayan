typedef struct bynt_main__Stat bynt_main__Stat;
typedef struct bynt_list_main__Stat bynt_list_main__Stat;
typedef struct bynt_map_str_main__Stat bynt_map_str_main__Stat;
struct bynt_main__Stat {
    int64_t hits;
    int64_t total;
};
struct bynt_list_main__Stat {
    bynt_main__Stat* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_map_str_main__Stat {
    byn_map_hdr h;
    byn_str* keys;
    bynt_main__Stat* vals;
};