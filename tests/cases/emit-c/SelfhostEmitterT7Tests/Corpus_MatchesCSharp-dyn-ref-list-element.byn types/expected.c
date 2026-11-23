typedef struct byn_dyn_main__IThing byn_dyn_main__IThing;
typedef struct bynt_list_main__S bynt_list_main__S;
typedef struct bynt_main__S bynt_main__S;
struct byn_vt_main__IThing {
    int64_t (*get)(void* self);
};
struct byn_dyn_main__IThing {
    void* data;
    const struct byn_vt_main__IThing* vt;
};
struct bynt_list_main__S {
    bynt_main__S* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_main__S {
    int64_t n;
};