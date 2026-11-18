typedef struct bynt_fn1f_str_i64 bynt_fn1f_str_i64;
typedef struct byn_err byn_err;
struct bynt_fn1f_str_i64 {
    byn_err (*fn)(void* env, byn_str a0, int64_t* byn_out);
    void* env;
};
struct byn_err {
    uint32_t code;
    union {
        struct { int32_t signal; byn_str stdout_; byn_str stderr_; } e10;
        struct { int64_t after; byn_str stdout_; byn_str stderr_; } e11;
        struct { int64_t at; } e12;
        struct { int64_t at; byn_str why; } e13;
        struct { int64_t at; } e15;
    } p;
};