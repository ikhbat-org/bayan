typedef struct bynt_list_main__B bynt_list_main__B;
typedef struct bynt_main__B bynt_main__B;
typedef struct bynt_list_i64 bynt_list_i64;
struct bynt_list_main__B {
    bynt_main__B* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_list_i64 {
    int64_t* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_main__B {
    bynt_list_i64 items;
};