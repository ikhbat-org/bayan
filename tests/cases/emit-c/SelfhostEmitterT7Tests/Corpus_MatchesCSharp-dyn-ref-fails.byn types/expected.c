typedef struct byn_err byn_err;
typedef struct byn_dyn_main__IParser byn_dyn_main__IParser;
typedef struct bynt_main__Digits bynt_main__Digits;
struct byn_err {
    uint32_t code;
    union {
        struct { int32_t signal; byn_str stdout_; byn_str stderr_; } e10;
        struct { int64_t after; byn_str stdout_; byn_str stderr_; } e11;
        struct { int64_t at; } e12;
        struct { int64_t at; } e15;
    } p;
};
struct byn_vt_main__IParser {
    byn_err (*parse)(void* self, byn_str a0, int64_t* byn_out);
    byn_err (*check)(void* self, byn_str a0);
};
struct byn_dyn_main__IParser {
    void* data;
    const struct byn_vt_main__IParser* vt;
};
struct bynt_main__Digits {
    int64_t base;
};