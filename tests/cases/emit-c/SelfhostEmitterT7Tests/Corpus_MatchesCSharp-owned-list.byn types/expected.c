typedef struct bynt_opt_own_main__Node bynt_opt_own_main__Node;
typedef struct bynt_main__Tree bynt_main__Tree;
typedef struct bynt_main__Node bynt_main__Node;
typedef struct bynt_list_main__Tree bynt_list_main__Tree;
struct bynt_opt_own_main__Node {
    bool has;
    bynt_main__Node* value;
};
struct bynt_list_main__Tree {
    bynt_main__Tree* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_main__Tree {
    byn_str name;
    bynt_list_main__Tree children;
};
struct bynt_main__Node {
    int64_t item;
    bynt_opt_own_main__Node next;
};