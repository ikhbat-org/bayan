typedef struct bynt_main__S bynt_main__S;
typedef struct bynt_list_i64 bynt_list_i64;
typedef struct byn_dyn_main__IThing byn_dyn_main__IThing;
typedef struct bynt_span_i64 bynt_span_i64;
struct bynt_list_i64 {
    int64_t* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_main__S {
    bynt_list_i64 xs;
};
struct byn_vt_main__IThing {
    int64_t (*get)(void* self);
};
struct byn_dyn_main__IThing {
    void* data;
    const struct byn_vt_main__IThing* vt;
};
struct bynt_span_i64 {
    int64_t* ptr;
    int64_t len;
};