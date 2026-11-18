typedef struct bynt_main__Order bynt_main__Order;
struct bynt_main__Order {
    int64_t id;
    uint8_t tag;
    union {
        struct { int64_t payment; } paid;
    } u;
};