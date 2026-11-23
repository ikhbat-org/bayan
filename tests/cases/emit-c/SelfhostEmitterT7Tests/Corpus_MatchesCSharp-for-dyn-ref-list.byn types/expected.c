typedef struct bynt_list_main__Sq bynt_list_main__Sq;
typedef struct bynt_main__Sq bynt_main__Sq;
struct bynt_list_main__Sq {
    bynt_main__Sq* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_main__Sq {
    int64_t s;
};