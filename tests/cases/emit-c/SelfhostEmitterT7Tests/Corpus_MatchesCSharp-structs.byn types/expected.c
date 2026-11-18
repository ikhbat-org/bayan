typedef struct bynt_main__Point bynt_main__Point;
typedef struct bynt_main__Line bynt_main__Line;
typedef struct bynt_tup2_str_i32 bynt_tup2_str_i32;
struct bynt_main__Point {
    int64_t x;
    int64_t y;
};
struct bynt_main__Line {
    bynt_main__Point from;
    bynt_main__Point to;
    byn_str name;
};
struct bynt_tup2_str_i32 {
    byn_str item1;
    int32_t item2;
};