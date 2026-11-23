typedef struct bynt_main__Rows bynt_main__Rows;
typedef struct bynt_opt_i64 bynt_opt_i64;
struct bynt_main__Rows {
    int64_t at;
    int64_t limit;
};
struct bynt_opt_i64 {
    bool has;
    int64_t value;
};