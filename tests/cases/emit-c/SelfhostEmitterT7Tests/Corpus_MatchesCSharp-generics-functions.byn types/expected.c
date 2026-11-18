typedef struct bynt_main__Point bynt_main__Point;
typedef struct bynt_list_i64 bynt_list_i64;
typedef struct bynt_list_str bynt_list_str;
typedef struct bynt_span_i64 bynt_span_i64;
typedef struct bynt_span_str bynt_span_str;
struct bynt_main__Point {
    int64_t x;
    int64_t y;
};
struct bynt_list_i64 {
    int64_t* ptr;
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
struct bynt_span_i64 {
    int64_t* ptr;
    int64_t len;
};
struct bynt_span_str {
    byn_str* ptr;
    int64_t len;
};