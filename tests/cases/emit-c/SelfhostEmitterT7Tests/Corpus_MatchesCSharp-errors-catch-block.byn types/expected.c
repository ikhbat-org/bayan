typedef struct byn_err byn_err;
typedef struct bynt_span_str bynt_span_str;
struct byn_err {
    uint32_t code;
    union {
        struct { int32_t signal; byn_str stdout_; byn_str stderr_; } e10;
        struct { int64_t after; byn_str stdout_; byn_str stderr_; } e11;
        struct { int64_t at; } e12;
        struct { int64_t at; } e15;
    } p;
};
struct bynt_span_str {
    byn_str* ptr;
    int64_t len;
};