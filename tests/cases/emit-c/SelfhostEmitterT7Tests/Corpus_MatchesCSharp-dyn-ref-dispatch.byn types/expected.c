typedef struct byn_dyn_main__IShape byn_dyn_main__IShape;
typedef struct bynt_main__Square bynt_main__Square;
typedef struct bynt_main__Circle bynt_main__Circle;
struct byn_vt_main__IShape {
    int64_t (*area)(void* self);
    int64_t (*times)(void* self, int64_t a0);
    void (*describe)(void* self);
    byn_str (*get_name)(void* self);
};
struct byn_dyn_main__IShape {
    void* data;
    const struct byn_vt_main__IShape* vt;
};
struct bynt_main__Square {
    int64_t side;
};
struct bynt_main__Circle {
    int64_t r;
};