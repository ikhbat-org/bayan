typedef struct bynt_fn0_fn0f_i64 bynt_fn0_fn0f_i64;
typedef struct bynt_fn0f_fn0_i64 bynt_fn0f_fn0_i64;
typedef struct bynt_fn0_i64 bynt_fn0_i64;
typedef struct bynt_fn0f_i64 bynt_fn0f_i64;
typedef struct byn_err byn_err;
struct bynt_fn0_fn0f_i64 {
    bynt_fn0f_i64 (*fn)(void* env);
    void* env;
};
struct bynt_fn0f_fn0_i64 {
    byn_err (*fn)(void* env, bynt_fn0_i64* byn_out);
    void* env;
};
struct bynt_fn0_i64 {
    int64_t (*fn)(void* env);
    void* env;
};
struct bynt_fn0f_i64 {
    byn_err (*fn)(void* env, int64_t* byn_out);
    void* env;
};
struct byn_err {
    uint32_t code;
    union {
        struct { int32_t signal; byn_str stdout_; byn_str stderr_; } e10;
        struct { int64_t after; byn_str stdout_; byn_str stderr_; } e11;
        struct { int64_t at; } e12;
        struct { int64_t at; } e14;
    } p;
};