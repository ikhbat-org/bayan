typedef struct bynt_main__LineItem bynt_main__LineItem;
typedef struct bynt_main__Money bynt_main__Money;
struct bynt_main__Money {
    int64_t cents;
};
struct bynt_main__LineItem {
    byn_str name;
    bynt_main__Money unitPrice;
    int64_t qty;
};