typedef struct bynt_span_main__Token bynt_span_main__Token;
typedef struct bynt_fn1_main__Token_bool bynt_fn1_main__Token_bool;
typedef struct bynt_main__Token bynt_main__Token;
typedef struct bynt_fn2_main__Token_main__Token_bool bynt_fn2_main__Token_main__Token_bool;
typedef struct bynt_fn1f_str_str bynt_fn1f_str_str;
typedef struct byn_err byn_err;
struct bynt_span_main__Token {
    bynt_main__Token* ptr;
    int64_t len;
};
struct bynt_fn1_main__Token_bool {
    bool (*fn)(void* env, bynt_main__Token a0);
    void* env;
};
struct bynt_main__Token {
    byn_main_TokenKind kind;
    int64_t start;
    byn_str text;
};
struct bynt_fn2_main__Token_main__Token_bool {
    bool (*fn)(void* env, bynt_main__Token a0, bynt_main__Token a1);
    void* env;
};
struct bynt_fn1f_str_str {
    byn_err (*fn)(void* env, byn_str a0, byn_str* byn_out);
    void* env;
};
struct byn_err {
    uint32_t code;
    union {
        struct { int32_t signal; byn_str stdout_; byn_str stderr_; } e10;
        struct { int64_t after; byn_str stdout_; byn_str stderr_; } e11;
        struct { int64_t at; } e12;
        struct { int64_t at; byn_str why; } e13;
        struct { int64_t at; } e14;
    } p;
};