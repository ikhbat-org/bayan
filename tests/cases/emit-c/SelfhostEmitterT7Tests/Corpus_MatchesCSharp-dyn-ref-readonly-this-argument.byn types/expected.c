typedef struct byn_dyn_main__ICount byn_dyn_main__ICount;
typedef struct bynt_main__B bynt_main__B;
typedef struct bynt_span_i64 bynt_span_i64;
typedef struct bynt_list_i64 bynt_list_i64;
struct byn_vt_main__ICount {
    int64_t (*count)(void* self);
};
struct byn_dyn_main__ICount {
    void* data;
    const struct byn_vt_main__ICount* vt;
};
struct bynt_list_i64 {
    int64_t* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_main__B {
    bynt_list_i64 items;
};
struct bynt_span_i64 {
    int64_t* ptr;
    int64_t len;
};