typedef struct bynt_list_i64 bynt_list_i64;
typedef struct byn_main_Slot byn_main_Slot;
struct bynt_list_i64 {
    int64_t* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct byn_main_Slot {
    int32_t tag;
    union {
        struct { bynt_list_i64 items; } full;
    } u;
};