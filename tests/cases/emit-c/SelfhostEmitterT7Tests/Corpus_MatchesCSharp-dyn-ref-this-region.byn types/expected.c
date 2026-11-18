typedef struct bynt_main__Box bynt_main__Box;
typedef struct byn_dyn_main__IThing byn_dyn_main__IThing;
typedef struct bynt_main__S bynt_main__S;
struct bynt_main__S {
    int64_t n;
};
struct bynt_main__Box {
    bynt_main__S inner;
};
struct byn_vt_main__IThing {
    int64_t (*get)(void* self);
};
struct byn_dyn_main__IThing {
    void* data;
    const struct byn_vt_main__IThing* vt;
};