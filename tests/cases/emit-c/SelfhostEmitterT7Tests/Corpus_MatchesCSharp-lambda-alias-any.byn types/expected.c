typedef struct bynt_span_i32 bynt_span_i32;
typedef struct bynt_fn1_i32_bool bynt_fn1_i32_bool;
struct bynt_span_i32 {
    int32_t* ptr;
    int64_t len;
};
struct bynt_fn1_i32_bool {
    bool (*fn)(void* env, int32_t a0);
    void* env;
};