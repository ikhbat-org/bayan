typedef struct byn_main_Shape byn_main_Shape;
typedef struct bynt_list_main__Shape bynt_list_main__Shape;
typedef struct bynt_main__Slot bynt_main__Slot;
typedef struct bynt_opt_main__Shape bynt_opt_main__Shape;
typedef struct bynt_list_main__Token bynt_list_main__Token;
typedef struct byn_main_Token byn_main_Token;
struct byn_main_Shape {
    int32_t tag;
    union {
        struct { float r; } circle;
        struct { float w; float h; } rect;
    } u;
};
struct bynt_list_main__Shape {
    byn_main_Shape* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_main__Slot {
    byn_str label;
    byn_main_Shape shape;
};
struct bynt_opt_main__Shape {
    bool has;
    byn_main_Shape value;
};
struct bynt_list_main__Token {
    byn_main_Token* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct byn_main_Token {
    int32_t tag;
    union {
        struct { int64_t value; } number;
        struct { byn_str text; } word;
    } u;
};