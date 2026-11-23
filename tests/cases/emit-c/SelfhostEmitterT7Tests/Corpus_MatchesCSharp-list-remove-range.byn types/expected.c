typedef struct bynt_list_i64 bynt_list_i64;
typedef struct bynt_list_str bynt_list_str;
typedef struct bynt_arr5_str bynt_arr5_str;
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
struct bynt_arr5_str {
    byn_str v[5];
};