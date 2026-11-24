typedef struct bynt_main__C bynt_main__C;
typedef struct bynt_span_i64 bynt_span_i64;
typedef struct bynt_list_i64 bynt_list_i64;
struct bynt_main__C {
    int64_t n;
};
struct bynt_span_i64 {
    int64_t* ptr;
    int64_t len;
};
struct bynt_list_i64 {
    int64_t* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};