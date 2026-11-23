typedef struct bynt_opt_sym bynt_opt_sym;
typedef struct bynt_main__Entry bynt_main__Entry;
typedef struct bynt_list_sym bynt_list_sym;
typedef struct bynt_map_sym_i32 bynt_map_sym_i32;
struct bynt_opt_sym {
    bool has;
    byn_sym value;
};
struct bynt_main__Entry {
    byn_sym name;
    int32_t rank;
};
struct bynt_list_sym {
    byn_sym* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_map_sym_i32 {
    byn_map_hdr h;
    byn_sym* keys;
    int32_t* vals;
};