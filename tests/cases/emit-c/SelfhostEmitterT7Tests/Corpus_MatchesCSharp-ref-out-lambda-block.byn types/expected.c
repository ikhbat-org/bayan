typedef struct bynt_fn1_i64_i64 bynt_fn1_i64_i64;
struct bynt_fn1_i64_i64 {
    int64_t (*fn)(void* env, int64_t a0);
    void* env;
};