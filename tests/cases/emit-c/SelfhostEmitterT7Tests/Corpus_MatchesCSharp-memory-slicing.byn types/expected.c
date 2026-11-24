typedef struct bynt_arr5_i64 bynt_arr5_i64;
typedef struct bynt_span_i64 bynt_span_i64;
struct bynt_arr5_i64 {
    int64_t v[5];
};
struct bynt_span_i64 {
    int64_t* ptr;
    int64_t len;
};