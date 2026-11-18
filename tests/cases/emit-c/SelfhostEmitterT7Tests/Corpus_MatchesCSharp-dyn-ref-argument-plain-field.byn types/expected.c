typedef struct byn_dyn_main__IC byn_dyn_main__IC;
typedef struct bynt_main__B bynt_main__B;
typedef struct bynt_span_i64 bynt_span_i64;
typedef struct bynt_list_i64 bynt_list_i64;
typedef struct bynt_main__C bynt_main__C;
struct byn_vt_main__IC {
    void (*bump)(void* self);
};
struct byn_dyn_main__IC {
    void* data;
    const struct byn_vt_main__IC* vt;
};
struct bynt_list_i64 {
    int64_t* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_main__C {
    int64_t n;
};
struct bynt_main__B {
    bynt_list_i64 items;
    bynt_main__C c;
};
struct bynt_span_i64 {
    int64_t* ptr;
    int64_t len;
};