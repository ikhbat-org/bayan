typedef struct byn_dyn_main__IStack byn_dyn_main__IStack;
typedef struct bynt_main__Stack bynt_main__Stack;
typedef struct bynt_list_i64 bynt_list_i64;
struct byn_vt_main__IStack {
    void (*push)(void* self, int64_t a0);
    int64_t (*top)(void* self);
    int64_t (*get_count)(void* self);
};
struct byn_dyn_main__IStack {
    void* data;
    const struct byn_vt_main__IStack* vt;
};
struct bynt_list_i64 {
    int64_t* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_main__Stack {
    bynt_list_i64 items;
};