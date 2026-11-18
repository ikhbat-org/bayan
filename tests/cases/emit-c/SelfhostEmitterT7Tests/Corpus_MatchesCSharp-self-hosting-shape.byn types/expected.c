typedef struct byn_dyn_main__INode byn_dyn_main__INode;
typedef struct bynt_list_main__Token bynt_list_main__Token;
typedef struct bynt_main__TokenList bynt_main__TokenList;
typedef struct bynt_main__TokenStream bynt_main__TokenStream;
typedef struct bynt_main__Num bynt_main__Num;
typedef struct bynt_main__Add bynt_main__Add;
typedef struct bynt_main__Mul bynt_main__Mul;
typedef struct bynt_main__Token bynt_main__Token;
struct byn_vt_main__INode {
    int64_t (*eval)(void* self);
    byn_str (*describe)(void* self);
    byn_str (*get_name)(void* self);
};
struct byn_dyn_main__INode {
    void* data;
    const struct byn_vt_main__INode* vt;
};
struct bynt_list_main__Token {
    bynt_main__Token* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_main__TokenList {
    bynt_list_main__Token tokens;
};
struct bynt_main__TokenStream {
    bynt_list_main__Token tokens;
    int64_t at;
};
struct bynt_main__Num {
    int64_t value;
};
struct bynt_main__Add {
    int64_t left;
    int64_t right;
};
struct bynt_main__Mul {
    int64_t left;
    int64_t right;
};
struct bynt_main__Token {
    byn_main_TokenKind kind;
    int64_t value;
};