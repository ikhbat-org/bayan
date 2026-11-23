typedef struct bynt_main__Door bynt_main__Door;
typedef struct bynt_main__Probe bynt_main__Probe;
typedef struct bynt_list_i64 bynt_list_i64;
struct bynt_main__Door {
    int64_t id;
    uint8_t tag;
};
struct bynt_main__Probe {
    char unused;
};
struct bynt_list_i64 {
    int64_t* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};