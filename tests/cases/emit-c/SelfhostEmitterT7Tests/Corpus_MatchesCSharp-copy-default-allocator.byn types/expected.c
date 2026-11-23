typedef struct bynt_arr3_i64 bynt_arr3_i64;
typedef struct bynt_list_i64 bynt_list_i64;
struct bynt_arr3_i64 {
    int64_t v[3];
};
struct bynt_list_i64 {
    int64_t* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};