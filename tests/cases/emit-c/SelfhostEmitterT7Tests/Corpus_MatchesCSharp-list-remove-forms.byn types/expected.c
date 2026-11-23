typedef struct bynt_list_i64 bynt_list_i64;
typedef struct bynt_tup3_i64_i64_bool bynt_tup3_i64_i64_bool;
struct bynt_list_i64 {
    int64_t* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_tup3_i64_i64_bool {
    int64_t item1;
    int64_t item2;
    bool item3;
};