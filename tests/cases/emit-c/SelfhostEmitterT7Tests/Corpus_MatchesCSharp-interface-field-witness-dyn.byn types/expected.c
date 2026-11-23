typedef struct byn_dyn_main__INamed byn_dyn_main__INamed;
typedef struct bynt_main__Person bynt_main__Person;
struct byn_vt_main__INamed {
    byn_str (*greet)(void* self);
    byn_str (*get_name)(void* self);
};
struct byn_dyn_main__INamed {
    void* data;
    const struct byn_vt_main__INamed* vt;
};
struct bynt_main__Person {
    byn_str name;
};