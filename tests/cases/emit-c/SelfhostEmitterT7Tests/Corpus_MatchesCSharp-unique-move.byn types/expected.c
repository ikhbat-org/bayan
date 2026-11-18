typedef struct bynt_list_i64 bynt_list_i64;
typedef struct bynt_main__Bag bynt_main__Bag;
typedef struct bynt_list_list_i64 bynt_list_list_i64;
struct bynt_list_i64 {
    int64_t* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_main__Bag {
    byn_str name;
    bynt_list_i64 items;
};
struct bynt_list_list_i64 {
    bynt_list_i64* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};