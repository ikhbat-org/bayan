typedef struct bynt_list_i64 bynt_list_i64;
typedef struct bynt_list_f64 bynt_list_f64;
typedef struct bynt_list_str bynt_list_str;
typedef struct bynt_list_rune bynt_list_rune;
typedef struct bynt_list_i32 bynt_list_i32;
struct bynt_list_i64 {
    int64_t* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_list_f64 {
    double* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_list_str {
    byn_str* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_list_rune {
    uint32_t* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_list_i32 {
    int32_t* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};