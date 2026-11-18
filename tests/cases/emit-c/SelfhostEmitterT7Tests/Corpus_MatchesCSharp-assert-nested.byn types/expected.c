typedef struct bynt_main__Cart bynt_main__Cart;
typedef struct bynt_main__Money bynt_main__Money;
struct bynt_main__Money {
    int64_t cents;
};
struct bynt_main__Cart {
    bynt_main__Money subtotal;
    int64_t lines;
};