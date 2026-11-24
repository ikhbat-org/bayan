typedef struct bynt_res_i64 bynt_res_i64;
typedef struct byn_err byn_err;
struct byn_err {
    uint32_t code;
    union {
        struct { int32_t signal; byn_str stdout_; byn_str stderr_; } e10;
        struct { int64_t after; byn_str stdout_; byn_str stderr_; } e11;
        struct { int64_t at; } e12;
        struct { int64_t at; } e13;
        struct { int64_t at; } e15;
    } p;
};
struct bynt_res_i64 {
    byn_err err;
    int64_t value;
};