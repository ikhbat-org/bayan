typedef struct bynt_arr2_main__Booking_Field bynt_arr2_main__Booking_Field;
typedef struct bynt_list_builtin__Violation__main__Booking bynt_list_builtin__Violation__main__Booking;
typedef struct bynt_builtin__Violation__main__Booking bynt_builtin__Violation__main__Booking;
typedef struct byn_builtin_Rule byn_builtin_Rule;
typedef struct bynt_tup3_i64_i64_bool bynt_tup3_i64_i64_bool;
struct bynt_arr2_main__Booking_Field {
    byn_main_Booking_Field v[2];
};
struct bynt_list_builtin__Violation__main__Booking {
    bynt_builtin__Violation__main__Booking* ptr;
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
struct bynt_builtin__Violation__main__Booking {
    byn_main_Booking_Field field;
    byn_builtin_Rule rule;
};