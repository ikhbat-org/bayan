typedef struct bynt_main__Pair__i64__str bynt_main__Pair__i64__str;
typedef struct bynt_main__Pair__str__i64 bynt_main__Pair__str__i64;
typedef struct bynt_main__Pair__main__Suit__bool bynt_main__Pair__main__Suit__bool;
typedef struct byn_main_Option2__i64 byn_main_Option2__i64;
typedef struct byn_main_Option2__str byn_main_Option2__str;
typedef struct byn_main_Tree__i64 byn_main_Tree__i64;
typedef struct bynt_main__Box__str bynt_main__Box__str;
typedef struct bynt_map_main__Suit_i64 bynt_map_main__Suit_i64;
typedef struct bynt_map_str_i64 bynt_map_str_i64;
typedef struct bynt_main__Slot__i64 bynt_main__Slot__i64;
typedef struct bynt_main__Slot__str bynt_main__Slot__str;
typedef struct bynt_main__Pair__bool__main__Suit bynt_main__Pair__bool__main__Suit;
typedef struct bynt_main__Pair__i64__i64 bynt_main__Pair__i64__i64;
typedef struct bynt_list_str bynt_list_str;
typedef struct bynt_opt_i64 bynt_opt_i64;
typedef struct bynt_opt_str bynt_opt_str;
struct bynt_main__Pair__i64__str {
    int64_t a;
    byn_str b;
};
struct bynt_main__Pair__str__i64 {
    byn_str a;
    int64_t b;
};
struct bynt_main__Pair__main__Suit__bool {
    byn_main_Suit a;
    bool b;
};
struct byn_main_Option2__i64 {
    int32_t tag;
    union {
        struct { int64_t v; } some;
    } u;
};
struct byn_main_Option2__str {
    int32_t tag;
    union {
        struct { byn_str v; } some;
    } u;
};
struct bynt_main__Pair__i64__i64 {
    int64_t a;
    int64_t b;
};
struct byn_main_Tree__i64 {
    int32_t tag;
    union {
        struct { int64_t v; } leaf;
        struct { bynt_main__Pair__i64__i64 kids; } node;
    } u;
};
struct bynt_list_str {
    byn_str* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_main__Box__str {
    byn_str value;
    bynt_list_str history;
};
struct bynt_map_main__Suit_i64 {
    byn_map_hdr h;
    byn_main_Suit* keys;
    int64_t* vals;
};
struct bynt_map_str_i64 {
    byn_map_hdr h;
    byn_str* keys;
    int64_t* vals;
};
struct bynt_opt_i64 {
    bool has;
    int64_t value;
};
struct bynt_main__Slot__i64 {
    bynt_opt_i64 value;
    int64_t useCount;
};
struct bynt_opt_str {
    bool has;
    byn_str value;
};
struct bynt_main__Slot__str {
    bynt_opt_str value;
    int64_t useCount;
};
struct bynt_main__Pair__bool__main__Suit {
    bool a;
    byn_main_Suit b;
};