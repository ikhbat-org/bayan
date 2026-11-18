typedef struct bynt_list_list_main__C bynt_list_list_main__C;
typedef struct bynt_list_main__C bynt_list_main__C;
typedef struct bynt_main__C bynt_main__C;
struct bynt_list_list_main__C {
    bynt_list_main__C* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_list_main__C {
    bynt_main__C* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_main__C {
    int64_t n;
};