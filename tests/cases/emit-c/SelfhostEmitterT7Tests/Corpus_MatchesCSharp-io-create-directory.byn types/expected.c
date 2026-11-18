typedef struct bynt_list_str bynt_list_str;
typedef struct bynt_arr1_u8 bynt_arr1_u8;
struct bynt_list_str {
    byn_str* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_arr1_u8 {
    uint8_t v[1];
};