typedef struct bynt_main__Pad bynt_main__Pad;
typedef struct bynt_map_main__Pad_i32 bynt_map_main__Pad_i32;
struct bynt_main__Pad {
    bool flag;
    int64_t id;
};
struct bynt_map_main__Pad_i32 {
    byn_map_hdr h;
    bynt_main__Pad* keys;
    int32_t* vals;
};