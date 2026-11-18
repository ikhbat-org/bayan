typedef struct bynt_arr6_u8 bynt_arr6_u8;
typedef struct bynt_arr2_str bynt_arr2_str;
typedef struct bynt_list_u8 bynt_list_u8;
struct bynt_arr6_u8 {
    uint8_t v[6];
};
struct bynt_arr2_str {
    byn_str v[2];
};
struct bynt_list_u8 {
    uint8_t* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};