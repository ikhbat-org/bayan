typedef struct bynt_main__P bynt_main__P;
typedef struct bynt_main__Inner bynt_main__Inner;
typedef struct bynt_opt_bool bynt_opt_bool;
struct bynt_main__Inner {
    byn_str name;
    uint32_t mark;
};
struct bynt_opt_bool {
    bool has;
    bool value;
};
struct bynt_main__P {
    int64_t x;
    bynt_main__Inner inner;
    bynt_opt_bool flag;
};