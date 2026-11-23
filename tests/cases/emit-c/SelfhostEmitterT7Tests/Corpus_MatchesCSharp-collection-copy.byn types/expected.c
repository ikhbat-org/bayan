typedef struct bynt_span_i64 bynt_span_i64;
typedef struct bynt_list_i64 bynt_list_i64;
typedef struct bynt_map_i64_i64 bynt_map_i64_i64;
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
struct bynt_map_i64_i64 {
    byn_map_hdr h;
    int64_t* keys;
    int64_t* vals;
};