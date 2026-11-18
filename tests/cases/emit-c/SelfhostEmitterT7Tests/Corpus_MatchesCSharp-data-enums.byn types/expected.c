typedef struct bynt_list_main__Token bynt_list_main__Token;
struct bynt_list_main__Token {
    byn_main_Token* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};