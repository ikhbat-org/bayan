typedef struct bynt_span_u8 bynt_span_u8;
typedef struct bynt_span_i64 bynt_span_i64;
typedef struct bynt_list_i64 bynt_list_i64;
typedef struct bynt_arr3_i64 bynt_arr3_i64;
struct bynt_span_u8 {
    uint8_t* ptr;
    int64_t len;
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
struct bynt_arr3_i64 {
    int64_t v[3];
};