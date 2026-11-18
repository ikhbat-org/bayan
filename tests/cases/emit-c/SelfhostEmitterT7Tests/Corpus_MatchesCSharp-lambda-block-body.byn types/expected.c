typedef struct bynt_fn1u1_i64_console_i64 bynt_fn1u1_i64_console_i64;
typedef struct bynt_fn1u1_i64_console_void bynt_fn1u1_i64_console_void;
struct bynt_fn1u1_i64_console_i64 {
    int64_t (*fn)(void* env, int64_t a0);
    void* env;
};
struct bynt_fn1u1_i64_console_void {
    void (*fn)(void* env, int64_t a0);
    void* env;
};