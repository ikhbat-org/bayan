typedef struct bynt_main__Bag bynt_main__Bag;
typedef struct byn_dyn_main__IThing byn_dyn_main__IThing;
typedef struct bynt_map_i64_main__S bynt_map_i64_main__S;
typedef struct bynt_main__S bynt_main__S;
struct bynt_map_i64_main__S {
    byn_map_hdr h;
    int64_t* keys;
    bynt_main__S* vals;
};
struct bynt_main__Bag {
    bynt_map_i64_main__S items;
};
struct byn_vt_main__IThing {
    int64_t (*get)(void* self);
};
struct byn_dyn_main__IThing {
    void* data;
    const struct byn_vt_main__IThing* vt;
};
struct bynt_main__S {
    int64_t n;
};