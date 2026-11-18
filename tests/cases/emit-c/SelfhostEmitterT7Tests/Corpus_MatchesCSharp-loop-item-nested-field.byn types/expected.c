typedef struct bynt_span_str bynt_span_str;
typedef struct bynt_list_str bynt_list_str;
typedef struct bynt_list_main__Outer bynt_list_main__Outer;
typedef struct bynt_main__Outer bynt_main__Outer;
typedef struct bynt_main__Inner bynt_main__Inner;
struct bynt_span_str {
    byn_str* ptr;
    int64_t len;
};
struct bynt_list_str {
    byn_str* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_list_main__Outer {
    bynt_main__Outer* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_main__Inner {
    bynt_list_str list;
};
struct bynt_main__Outer {
    bynt_main__Inner a;
};