typedef struct bynt_main__Lamp bynt_main__Lamp;
typedef struct bynt_main__Gate bynt_main__Gate;
typedef struct byn_main_Mode byn_main_Mode;
typedef struct byn_main_Shape byn_main_Shape;
struct bynt_main__Lamp {
    uint8_t tag;
};
struct bynt_main__Gate {
    uint8_t tag;
    union {
        struct { int64_t width; } open;
    } u;
};
struct byn_main_Mode {
    int32_t tag;
};
struct byn_main_Shape {
    int32_t tag;
    union {
        struct { int64_t side; } square;
    } u;
};