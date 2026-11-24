typedef struct bynt_list_main__S bynt_list_main__S;
typedef struct bynt_main__S bynt_main__S;
struct bynt_list_main__S {
    bynt_main__S* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_main__S {
    int64_t n;
};