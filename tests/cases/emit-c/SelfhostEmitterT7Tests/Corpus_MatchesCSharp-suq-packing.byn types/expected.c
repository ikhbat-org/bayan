typedef struct bynt_main__BoxSize bynt_main__BoxSize;
typedef struct bynt_span_main__PackItem bynt_span_main__PackItem;
typedef struct bynt_span_i32 bynt_span_i32;
typedef struct bynt_span_main__PackedBox bynt_span_main__PackedBox;
typedef struct bynt_list_main__PackItem bynt_list_main__PackItem;
typedef struct bynt_main__PackItem bynt_main__PackItem;
typedef struct bynt_main__PackedBox bynt_main__PackedBox;
struct bynt_main__BoxSize {
    byn_str name;
    int64_t capacity;
    int64_t tare;
};
struct bynt_span_main__PackItem {
    bynt_main__PackItem* ptr;
    int64_t len;
};
struct bynt_span_i32 {
    int32_t* ptr;
    int64_t len;
};
struct bynt_span_main__PackedBox {
    bynt_main__PackedBox* ptr;
    int64_t len;
};
struct bynt_list_main__PackItem {
    bynt_main__PackItem* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_main__PackItem {
    byn_str sku;
    int64_t grams;
    uint8_t aisle;
    uint16_t bay;
};
struct bynt_main__PackedBox {
    int32_t kind;
    int64_t load;
};