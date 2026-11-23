typedef struct bynt_opt_main__Color bynt_opt_main__Color;
typedef struct bynt_main__Card bynt_main__Card;
typedef struct bynt_list_main__Suit bynt_list_main__Suit;
typedef struct bynt_opt_main__Suit bynt_opt_main__Suit;
struct bynt_opt_main__Color {
    bool has;
    byn_main_Color value;
};
struct bynt_main__Card {
    byn_main_Suit suit;
    int64_t rank;
};
struct bynt_list_main__Suit {
    byn_main_Suit* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_opt_main__Suit {
    bool has;
    byn_main_Suit value;
};