typedef struct byn_err byn_err;
typedef struct bynt_main__Line bynt_main__Line;
typedef struct bynt_main__Order bynt_main__Order;
typedef struct bynt_main__Money bynt_main__Money;
typedef struct bynt_list_main__Line bynt_list_main__Line;
typedef struct byn_main_OrderState byn_main_OrderState;
struct byn_err {
    uint32_t code;
    union {
        struct { int32_t signal; byn_str stdout_; byn_str stderr_; } e10;
        struct { int64_t after; byn_str stdout_; byn_str stderr_; } e11;
        struct { int64_t at; } e12;
        struct { int64_t at; } e20;
    } p;
};
struct bynt_main__Money {
    int64_t cents;
    byn_main_Currency currency;
};
struct bynt_main__Line {
    byn_str sku;
    int32_t qty;
    bynt_main__Money unitPrice;
    int64_t unitGrams;
    byn_main_LineStatus status;
};
struct bynt_list_main__Line {
    bynt_main__Line* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct byn_main_OrderState {
    int32_t tag;
    union {
        struct { byn_str payment; } paid;
        struct { byn_str payment; byn_str tracking; } shipped;
        struct { byn_str reason; } cancelled;
    } u;
};
struct bynt_main__Order {
    int64_t id;
    byn_main_Currency currency;
    bynt_list_main__Line lines;
    byn_main_OrderState state;
};