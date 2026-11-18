typedef struct bynt_map_str_i64 bynt_map_str_i64;
typedef struct bynt_res_map_str_i64 bynt_res_map_str_i64;
typedef struct bynt_main__Store bynt_main__Store;
typedef struct byn_main_Slot byn_main_Slot;
typedef struct bynt_list_map_str_i64 bynt_list_map_str_i64;
typedef struct bynt_map_i64_map_str_i64 bynt_map_i64_map_str_i64;
typedef struct bynt_arr2_map_str_i64 bynt_arr2_map_str_i64;
typedef struct bynt_tup2_map_str_i64_i32 bynt_tup2_map_str_i64_i32;
typedef struct bynt_opt_map_str_i64 bynt_opt_map_str_i64;
typedef struct bynt_main__Counted bynt_main__Counted;
typedef struct bynt_main__Named bynt_main__Named;
typedef struct byn_err byn_err;
typedef struct bynt_map_i64_i64 bynt_map_i64_i64;
struct bynt_map_str_i64 {
    byn_map_hdr h;
    byn_str* keys;
    int64_t* vals;
};
struct byn_err {
    uint32_t code;
    union {
        struct { int32_t signal; byn_str stdout_; byn_str stderr_; } e10;
        struct { int64_t after; byn_str stdout_; byn_str stderr_; } e11;
        struct { int64_t at; } e12;
        struct { int64_t at; } e14;
    } p;
};
struct bynt_res_map_str_i64 {
    byn_err err;
    bynt_map_str_i64 value;
};
struct bynt_main__Store {
    byn_str name;
    bynt_map_str_i64 data;
};
struct byn_main_Slot {
    int32_t tag;
    union {
        struct { bynt_map_str_i64 data; } full;
    } u;
};
struct bynt_list_map_str_i64 {
    bynt_map_str_i64* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_map_i64_map_str_i64 {
    byn_map_hdr h;
    int64_t* keys;
    bynt_map_str_i64* vals;
};
struct bynt_arr2_map_str_i64 {
    bynt_map_str_i64 v[2];
};
struct bynt_tup2_map_str_i64_i32 {
    bynt_map_str_i64 item1;
    int32_t item2;
};
struct bynt_opt_map_str_i64 {
    bool has;
    bynt_map_str_i64 value;
};
struct bynt_main__Counted {
    int64_t n;
};
struct bynt_map_i64_i64 {
    byn_map_hdr h;
    int64_t* keys;
    int64_t* vals;
};
struct bynt_main__Named {
    byn_str name;
    bynt_map_i64_i64 m;
};