typedef struct bynt_list_i64 bynt_list_i64;
typedef struct bynt_main__Ledger bynt_main__Ledger;
typedef struct bynt_map_str_i64 bynt_map_str_i64;
typedef struct bynt_opt_list_i64 bynt_opt_list_i64;
typedef struct bynt_list_list_i64 bynt_list_list_i64;
typedef struct bynt_list_list_list_i64 bynt_list_list_list_i64;
typedef struct bynt_map_str_list_i64 bynt_map_str_list_i64;
struct bynt_list_i64 {
    int64_t* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_opt_list_i64 {
    bool has;
    bynt_list_i64 value;
};
struct bynt_main__Ledger {
    byn_str name;
    bynt_list_i64 items;
    bynt_opt_list_i64 pending;
};
struct bynt_map_str_i64 {
    byn_map_hdr h;
    byn_str* keys;
    int64_t* vals;
};
struct bynt_list_list_i64 {
    bynt_list_i64* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_list_list_list_i64 {
    bynt_list_list_i64* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_map_str_list_i64 {
    byn_map_hdr h;
    byn_str* keys;
    bynt_list_i64* vals;
};