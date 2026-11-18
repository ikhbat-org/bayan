typedef struct bynt_span_i64 bynt_span_i64;
typedef struct bynt_main__W bynt_main__W;
typedef struct bynt_list_i64 bynt_list_i64;
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
struct bynt_main__W {
    bynt_list_i64 items;
};