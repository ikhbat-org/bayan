typedef struct bynt_span_u32 bynt_span_u32;
typedef struct bynt_arr6_u32 bynt_arr6_u32;
struct bynt_span_u32 {
    uint32_t* ptr;
    int64_t len;
};
struct bynt_arr6_u32 {
    uint32_t v[6];
};