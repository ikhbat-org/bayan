typedef struct byn_main_Mode byn_main_Mode;
typedef struct byn_main_Reply byn_main_Reply;
typedef struct bynt_list_main__Mode bynt_list_main__Mode;
struct byn_main_Mode {
    int32_t tag;
};
struct byn_main_Reply {
    int32_t tag;
    union {
        struct { byn_str to; } moved;
    } u;
};
struct bynt_list_main__Mode {
    byn_main_Mode* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};