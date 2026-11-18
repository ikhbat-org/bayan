typedef struct bynt_arr1_u8 bynt_arr1_u8;
typedef struct bynt_arr2_str bynt_arr2_str;
typedef struct bynt_arr2_u8 bynt_arr2_u8;
typedef struct bynt_map_str_opt_str bynt_map_str_opt_str;
typedef struct bynt_list_u8 bynt_list_u8;
typedef struct bynt_opt_str bynt_opt_str;
struct bynt_arr1_u8 {
    uint8_t v[1];
};
struct bynt_arr2_str {
    byn_str v[2];
};
struct bynt_arr2_u8 {
    uint8_t v[2];
};
struct bynt_map_str_opt_str {
    byn_map_hdr h;
    byn_str* keys;
    bynt_opt_str* vals;
};
struct bynt_list_u8 {
    uint8_t* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_opt_str {
    bool has;
    byn_str value;
};