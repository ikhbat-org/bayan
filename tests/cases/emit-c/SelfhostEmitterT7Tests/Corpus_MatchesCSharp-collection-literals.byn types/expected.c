typedef struct bynt_span_i32 bynt_span_i32;
typedef struct bynt_map_str_i32 bynt_map_str_i32;
typedef struct bynt_map_str_i64 bynt_map_str_i64;
typedef struct bynt_map_str_str bynt_map_str_str;
typedef struct bynt_arr3_i32 bynt_arr3_i32;
typedef struct bynt_list_i32 bynt_list_i32;
typedef struct bynt_arr2_i32 bynt_arr2_i32;
typedef struct bynt_arr5_i32 bynt_arr5_i32;
typedef struct bynt_arr6_i32 bynt_arr6_i32;
struct bynt_span_i32 {
    int32_t* ptr;
    int64_t len;
};
struct bynt_map_str_i32 {
    byn_map_hdr h;
    byn_str* keys;
    int32_t* vals;
};
struct bynt_map_str_i64 {
    byn_map_hdr h;
    byn_str* keys;
    int64_t* vals;
};
struct bynt_map_str_str {
    byn_map_hdr h;
    byn_str* keys;
    byn_str* vals;
};
struct bynt_arr3_i32 {
    int32_t v[3];
};
struct bynt_list_i32 {
    int32_t* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_arr2_i32 {
    int32_t v[2];
};
struct bynt_arr5_i32 {
    int32_t v[5];
};
struct bynt_arr6_i32 {
    int32_t v[6];
};