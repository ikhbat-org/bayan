typedef struct byn_dyn_main__ICounter byn_dyn_main__ICounter;
typedef struct bynt_main__Counter bynt_main__Counter;
typedef struct bynt_main__Pair bynt_main__Pair;
struct byn_vt_main__ICounter {
    void (*bump)(void* self, int64_t a0);
    void (*report)(void* self);
    int64_t (*get_value)(void* self);
};
struct byn_dyn_main__ICounter {
    void* data;
    const struct byn_vt_main__ICounter* vt;
};
struct bynt_main__Counter {
    int64_t n;
};
struct bynt_main__Pair {
    bynt_main__Counter left;
    bynt_main__Counter right;
};