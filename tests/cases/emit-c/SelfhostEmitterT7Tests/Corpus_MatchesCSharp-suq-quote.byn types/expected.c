typedef struct bynt_span_main__PriceLine bynt_span_main__PriceLine;
typedef struct bynt_main__Policy bynt_main__Policy;
typedef struct bynt_main__Quote bynt_main__Quote;
typedef struct bynt_main__Money bynt_main__Money;
typedef struct bynt_main__Deal bynt_main__Deal;
typedef struct bynt_list_main__PriceLine bynt_list_main__PriceLine;
typedef struct bynt_main__PriceLine bynt_main__PriceLine;
typedef struct bynt_list_main__Promotion bynt_list_main__Promotion;
typedef struct bynt_list_main__ShippingBand bynt_list_main__ShippingBand;
typedef struct byn_main_Promotion byn_main_Promotion;
typedef struct bynt_main__ShippingBand bynt_main__ShippingBand;
struct bynt_span_main__PriceLine {
    bynt_main__PriceLine* ptr;
    int64_t len;
};
struct bynt_list_main__Promotion {
    byn_main_Promotion* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_list_main__ShippingBand {
    bynt_main__ShippingBand* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_main__Policy {
    byn_main_Currency currency;
    int64_t taxBp;
    bynt_list_main__Promotion promotions;
    bynt_list_main__ShippingBand bands;
};
struct bynt_main__Money {
    int64_t cents;
    byn_main_Currency currency;
};
struct bynt_main__Quote {
    bynt_main__Money subtotal;
    bynt_main__Money discount;
    bynt_main__Money shipping;
    bynt_main__Money tax;
};
struct bynt_main__Deal {
    int32_t buy;
    int32_t free;
};
struct bynt_list_main__PriceLine {
    bynt_main__PriceLine* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_main__PriceLine {
    byn_str key;
    int32_t qty;
    bynt_main__Money unitPrice;
    int64_t unitGrams;
};
struct byn_main_Promotion {
    int32_t tag;
    union {
        struct { int64_t rateBp; int64_t minimumCents; } percentOff;
        struct { byn_str key; int32_t buy; int32_t free; } buyGetFree;
        struct { int64_t thresholdCents; } freeShippingOver;
    } u;
};
struct bynt_main__ShippingBand {
    int64_t upToGrams;
    int64_t feeCents;
};