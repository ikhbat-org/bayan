typedef struct bynt_map_str_i64 bynt_map_str_i64;
typedef struct bynt_list_i64 bynt_list_i64;
typedef struct bynt_opt_i64 bynt_opt_i64;
typedef struct bynt_main__E bynt_main__E;
typedef struct bynt_tup2_i64_bool bynt_tup2_i64_bool;
typedef struct bynt_fn1_i64_i64 bynt_fn1_i64_i64;
typedef struct byn_dyn_main__IBox byn_dyn_main__IBox;
typedef struct bynt_main__Pt bynt_main__Pt;
typedef struct bynt_list_main__Pt bynt_list_main__Pt;
typedef struct bynt_opt_main__Pt bynt_opt_main__Pt;
typedef struct bynt_res_i64 bynt_res_i64;
typedef struct bynt_arr3_i64 bynt_arr3_i64;
typedef struct bynt_span_i64 bynt_span_i64;
typedef struct bynt_tup2_list_i64_map_str_i64 bynt_tup2_list_i64_map_str_i64;
typedef struct byn_err byn_err;
struct bynt_map_str_i64 {
    byn_map_hdr h;
    byn_str* keys;
    int64_t* vals;
};
struct bynt_list_i64 {
    int64_t* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_opt_i64 {
    bool has;
    int64_t value;
};
struct bynt_main__E {
    char unused;
};
struct bynt_tup2_i64_bool {
    int64_t item1;
    bool item2;
};
struct bynt_fn1_i64_i64 {
    int64_t (*fn)(void* env, int64_t a0);
    void* env;
};
struct byn_vt_main__IBox {
    int64_t (*get_n)(void* self);
};
struct byn_dyn_main__IBox {
    void* data;
    const struct byn_vt_main__IBox* vt;
};
struct bynt_main__Pt {
    char unused;
};
struct bynt_list_main__Pt {
    bynt_main__Pt* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_opt_main__Pt {
    bool has;
    bynt_main__Pt value;
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
struct bynt_res_i64 {
    byn_err err;
    int64_t value;
};
struct bynt_arr3_i64 {
    int64_t v[3];
};
struct bynt_span_i64 {
    int64_t* ptr;
    int64_t len;
};
struct bynt_tup2_list_i64_map_str_i64 {
    bynt_list_i64 item1;
    bynt_map_str_i64 item2;
};