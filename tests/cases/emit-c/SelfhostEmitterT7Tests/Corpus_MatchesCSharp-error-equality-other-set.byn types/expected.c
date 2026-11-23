typedef struct byn_err byn_err;
typedef struct bynt_list_i64 bynt_list_i64;
struct bynt_list_i64 {
    int64_t* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct byn_err {
    uint32_t code;
    union {
        struct { int32_t signal; byn_str stdout_; byn_str stderr_; } e10;
        struct { int64_t after; byn_str stdout_; byn_str stderr_; } e11;
        struct { int64_t at; } e12;
        struct { bynt_list_i64 items; } e13;
        struct { int64_t at; } e14;
        struct { int64_t at; } e16;
    } p;
};