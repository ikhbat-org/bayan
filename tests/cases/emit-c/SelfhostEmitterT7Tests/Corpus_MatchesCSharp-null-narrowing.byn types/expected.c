typedef struct bynt_opt_i64 bynt_opt_i64;
typedef struct bynt_opt_main__Box bynt_opt_main__Box;
typedef struct bynt_main__Box bynt_main__Box;
struct bynt_opt_i64 {
    bool has;
    int64_t value;
};
struct bynt_main__Box {
    int64_t v;
};
struct bynt_opt_main__Box {
    bool has;
    bynt_main__Box value;
};