typedef struct bynt_main__Order bynt_main__Order;
typedef struct bynt_opt_main__Order bynt_opt_main__Order;
struct bynt_main__Order {
    int64_t id;
    uint8_t tag;
    union {
        struct { int64_t payment; } paid;
        struct { int64_t payment; int64_t tracking; } shipped;
    } u;
};
struct bynt_opt_main__Order {
    bool has;
    bynt_main__Order value;
};