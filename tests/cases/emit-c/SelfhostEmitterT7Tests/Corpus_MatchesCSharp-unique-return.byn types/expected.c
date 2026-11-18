typedef struct bynt_list_i64 bynt_list_i64;
typedef struct bynt_main__Ledger bynt_main__Ledger;
struct bynt_list_i64 {
    int64_t* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_main__Ledger {
    byn_str name;
    bynt_list_i64 entries;
};