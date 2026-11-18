typedef struct bynt_fn1_i32_i32 bynt_fn1_i32_i32;
struct bynt_fn1_i32_i32 {
    int32_t (*fn)(void* env, int32_t a0);
    void* env;
};