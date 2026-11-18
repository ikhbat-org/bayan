typedef struct bynt_fn0_i64 bynt_fn0_i64;
typedef struct bynt_fn0_i32 bynt_fn0_i32;
typedef struct bynt_fn0_u8 bynt_fn0_u8;
typedef struct bynt_fn0_f64 bynt_fn0_f64;
typedef struct bynt_fn0_bool bynt_fn0_bool;
typedef struct bynt_fn0_rune bynt_fn0_rune;
typedef struct bynt_fn0_str bynt_fn0_str;
typedef struct bynt_main__Point bynt_main__Point;
typedef struct bynt_fn0_main__Point bynt_fn0_main__Point;
typedef struct bynt_fn0_main__Color bynt_fn0_main__Color;
typedef struct byn_main_Shape byn_main_Shape;
typedef struct bynt_fn0_main__Shape bynt_fn0_main__Shape;
typedef struct bynt_opt_i64 bynt_opt_i64;
typedef struct bynt_fn0_opt_i64 bynt_fn0_opt_i64;
typedef struct bynt_tup2_i64_str bynt_tup2_i64_str;
typedef struct bynt_fn0_tup2_i64_str bynt_fn0_tup2_i64_str;
typedef struct bynt_fn1_i64_i64 bynt_fn1_i64_i64;
typedef struct bynt_fn0_fn1_i64_i64 bynt_fn0_fn1_i64_i64;
struct bynt_fn0_i64 {
    int64_t (*fn)(void* env);
    void* env;
};
struct bynt_fn0_i32 {
    int32_t (*fn)(void* env);
    void* env;
};
struct bynt_fn0_u8 {
    uint8_t (*fn)(void* env);
    void* env;
};
struct bynt_fn0_f64 {
    double (*fn)(void* env);
    void* env;
};
struct bynt_fn0_bool {
    bool (*fn)(void* env);
    void* env;
};
struct bynt_fn0_rune {
    uint32_t (*fn)(void* env);
    void* env;
};
struct bynt_fn0_str {
    byn_str (*fn)(void* env);
    void* env;
};
struct bynt_main__Point {
    int64_t x;
    int64_t y;
};
struct bynt_fn0_main__Point {
    bynt_main__Point (*fn)(void* env);
    void* env;
};
struct bynt_fn0_main__Color {
    byn_main_Color (*fn)(void* env);
    void* env;
};
struct byn_main_Shape {
    int32_t tag;
    union {
        struct { int64_t r; } circle;
        struct { int64_t side; } square;
    } u;
};
struct bynt_fn0_main__Shape {
    byn_main_Shape (*fn)(void* env);
    void* env;
};
struct bynt_opt_i64 {
    bool has;
    int64_t value;
};
struct bynt_fn0_opt_i64 {
    bynt_opt_i64 (*fn)(void* env);
    void* env;
};
struct bynt_tup2_i64_str {
    int64_t item1;
    byn_str item2;
};
struct bynt_fn0_tup2_i64_str {
    bynt_tup2_i64_str (*fn)(void* env);
    void* env;
};
struct bynt_fn1_i64_i64 {
    int64_t (*fn)(void* env, int64_t a0);
    void* env;
};
struct bynt_fn0_fn1_i64_i64 {
    bynt_fn1_i64_i64 (*fn)(void* env);
    void* env;
};