typedef struct bynt_fn1_i64_i64 bynt_fn1_i64_i64;
typedef struct bynt_opt_i64 bynt_opt_i64;
typedef struct bynt_fn1u1_str_alloc_str bynt_fn1u1_str_alloc_str;
typedef struct bynt_main__Scale bynt_main__Scale;
struct bynt_fn1_i64_i64 {
    int64_t (*fn)(void* env, int64_t a0);
    void* env;
};
struct bynt_opt_i64 {
    bool has;
    int64_t value;
};
struct bynt_fn1u1_str_alloc_str {
    byn_str (*fn)(void* env, byn_str a0);
    void* env;
};
struct bynt_main__Scale {
    int64_t factor;
};