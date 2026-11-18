typedef struct bynt_fn1u1_i64_alloc_i64 bynt_fn1u1_i64_alloc_i64;
typedef struct bynt_list_i64 bynt_list_i64;
struct bynt_fn1u1_i64_alloc_i64 {
    int64_t (*fn)(void* env, int64_t a0);
    void* env;
};
struct bynt_list_i64 {
    int64_t* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};