typedef struct bynt_fn1_i32_i32 bynt_fn1_i32_i32;
typedef struct bynt_fn1_str_str bynt_fn1_str_str;
struct bynt_fn1_i32_i32 {
    int32_t (*fn)(void* env, int32_t a0);
    void* env;
};
struct bynt_fn1_str_str {
    byn_str (*fn)(void* env, byn_str a0);
    void* env;
};