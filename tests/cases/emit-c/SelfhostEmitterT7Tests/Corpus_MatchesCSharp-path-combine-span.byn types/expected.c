typedef struct bynt_span_str bynt_span_str;
typedef struct bynt_arr1_str bynt_arr1_str;
typedef struct bynt_arr3_str bynt_arr3_str;
typedef struct bynt_arr4_str bynt_arr4_str;
typedef struct bynt_list_str bynt_list_str;
struct bynt_span_str {
    byn_str* ptr;
    int64_t len;
};
struct bynt_arr1_str {
    byn_str v[1];
};
struct bynt_arr3_str {
    byn_str v[3];
};
struct bynt_arr4_str {
    byn_str v[4];
};
struct bynt_list_str {
    byn_str* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};