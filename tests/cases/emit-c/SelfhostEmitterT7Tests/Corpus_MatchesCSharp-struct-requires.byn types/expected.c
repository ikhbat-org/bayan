typedef struct bynt_main__Box bynt_main__Box;
typedef struct bynt_main__Qty bynt_main__Qty;
typedef struct bynt_list_builtin__Violation__main__Box bynt_list_builtin__Violation__main__Box;
typedef struct bynt_builtin__Violation__main__Box bynt_builtin__Violation__main__Box;
typedef struct byn_builtin_Rule byn_builtin_Rule;
typedef struct bynt_tup3_i64_i64_bool bynt_tup3_i64_i64_bool;
struct bynt_main__Box {
    int32_t w;
    int32_t h;
    byn_str label;
};
struct bynt_main__Qty {
    int32_t value;
};
struct bynt_list_builtin__Violation__main__Box {
    bynt_builtin__Violation__main__Box* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_tup3_i64_i64_bool {
    int64_t item1;
    int64_t item2;
    bool item3;
};
struct byn_builtin_Rule {
    int32_t tag;
    union {
        struct { bynt_tup3_i64_i64_bool bounds; } length;
        struct { bynt_tup3_i64_i64_bool bounds; } range;
    } u;
};
struct bynt_builtin__Violation__main__Box {
    byn_main_Box_Field field;
    byn_builtin_Rule rule;
};