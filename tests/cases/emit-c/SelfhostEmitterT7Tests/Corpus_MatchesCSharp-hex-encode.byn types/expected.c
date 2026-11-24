typedef struct bynt_list_u8 bynt_list_u8;
struct bynt_list_u8 {
    uint8_t* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};