typedef struct bynt_span_i64 bynt_span_i64;
typedef struct bynt_span_u8 bynt_span_u8;
struct bynt_span_i64 {
    int64_t* ptr;
    int64_t len;
};
struct bynt_span_u8 {
    uint8_t* ptr;
    int64_t len;
};