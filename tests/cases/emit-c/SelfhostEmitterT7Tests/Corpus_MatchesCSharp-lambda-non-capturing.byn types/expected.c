typedef struct bynt_fn1_i64_i64 bynt_fn1_i64_i64;
typedef struct bynt_fn1_i64_bool bynt_fn1_i64_bool;
typedef struct bynt_fn2_i64_i64_i64 bynt_fn2_i64_i64_i64;
typedef struct bynt_fn0_i64 bynt_fn0_i64;
struct bynt_fn1_i64_i64 {
    int64_t (*fn)(void* env, int64_t a0);
    void* env;
};
struct bynt_fn1_i64_bool {
    bool (*fn)(void* env, int64_t a0);
    void* env;
};
struct bynt_fn2_i64_i64_i64 {
    int64_t (*fn)(void* env, int64_t a0, int64_t a1);
    void* env;
};
struct bynt_fn0_i64 {
    int64_t (*fn)(void* env);
    void* env;
};