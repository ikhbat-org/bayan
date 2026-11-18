typedef struct byn_main_Expr byn_main_Expr;
struct byn_main_Expr {
    int32_t tag;
    union {
        struct { int64_t v; } lit;
        struct { byn_main_Expr* l; byn_main_Expr* r; } add;
        struct { byn_main_Expr* l; byn_main_Expr* r; } mul;
    } u;
};