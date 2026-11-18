typedef struct bynt_main__Box bynt_main__Box;
typedef struct bynt_list_i32 bynt_list_i32;
typedef struct bynt_opt_i32 bynt_opt_i32;
struct bynt_main__Box {
    byn_main_Op op;
    int32_t n;
};
struct bynt_list_i32 {
    int32_t* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_opt_i32 {
    bool has;
    int32_t value;
};