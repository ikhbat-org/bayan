typedef struct byn_main_Discount byn_main_Discount;
typedef struct bynt_opt_main__Discount bynt_opt_main__Discount;
struct byn_main_Discount {
    int32_t tag;
    union {
        struct { int64_t rate; } percentOff;
        struct { int64_t cents; byn_str label; } fixed;
    } u;
};
struct bynt_opt_main__Discount {
    bool has;
    byn_main_Discount value;
};