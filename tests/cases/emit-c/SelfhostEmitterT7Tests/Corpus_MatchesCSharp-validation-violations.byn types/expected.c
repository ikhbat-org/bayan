typedef struct bynt_main__Signup bynt_main__Signup;
typedef struct bynt_list_builtin__Violation__main__Signup bynt_list_builtin__Violation__main__Signup;
typedef struct bynt_builtin__Violation__main__Signup bynt_builtin__Violation__main__Signup;
typedef struct byn_builtin_Rule byn_builtin_Rule;
typedef struct bynt_tup3_i64_i64_bool bynt_tup3_i64_i64_bool;
struct bynt_main__Signup {
    byn_str name;
    int32_t age;
    byn_str password;
};
struct bynt_list_builtin__Violation__main__Signup {
    bynt_builtin__Violation__main__Signup* ptr;
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
struct bynt_builtin__Violation__main__Signup {
    byn_main_Signup_Field field;
    byn_builtin_Rule rule;
};