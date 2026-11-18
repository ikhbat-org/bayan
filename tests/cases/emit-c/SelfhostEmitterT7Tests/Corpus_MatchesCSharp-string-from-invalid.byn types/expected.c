typedef struct bynt_span_u8 bynt_span_u8;
typedef struct bynt_arr3_u8 bynt_arr3_u8;
typedef struct bynt_arr5_u8 bynt_arr5_u8;
typedef struct bynt_arr4_u8 bynt_arr4_u8;
typedef struct bynt_arr2_u8 bynt_arr2_u8;
struct bynt_span_u8 {
    uint8_t* ptr;
    int64_t len;
};
struct bynt_arr3_u8 {
    uint8_t v[3];
};
struct bynt_arr5_u8 {
    uint8_t v[5];
};
struct bynt_arr4_u8 {
    uint8_t v[4];
};
struct bynt_arr2_u8 {
    uint8_t v[2];
};