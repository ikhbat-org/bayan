typedef struct bynt_fn1_i64_bool bynt_fn1_i64_bool;
typedef struct bynt_fn1_str_str bynt_fn1_str_str;
typedef struct bynt_fn1_str_void bynt_fn1_str_void;
typedef struct bynt_fn2_i64_i64_i64 bynt_fn2_i64_i64_i64;
typedef struct bynt_fn1u1_str_alloc_str bynt_fn1u1_str_alloc_str;
typedef struct bynt_fn1u1_str_console_void bynt_fn1u1_str_console_void;
struct bynt_fn1_i64_bool {
    bool (*fn)(void* env, int64_t a0);
    void* env;
};
struct bynt_fn1_str_str {
    byn_str (*fn)(void* env, byn_str a0);
    void* env;
};
struct bynt_fn1_str_void {
    void (*fn)(void* env, byn_str a0);
    void* env;
};
struct bynt_fn2_i64_i64_i64 {
    int64_t (*fn)(void* env, int64_t a0, int64_t a1);
    void* env;
};
struct bynt_fn1u1_str_alloc_str {
    byn_str (*fn)(void* env, byn_str a0);
    void* env;
};
struct bynt_fn1u1_str_console_void {
    void (*fn)(void* env, byn_str a0);
    void* env;
};