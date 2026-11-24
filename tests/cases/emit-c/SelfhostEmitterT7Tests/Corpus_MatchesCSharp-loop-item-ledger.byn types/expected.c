typedef struct bynt_span_str bynt_span_str;
typedef struct bynt_list_str bynt_list_str;
typedef struct bynt_span_main__Expense bynt_span_main__Expense;
typedef struct bynt_list_main__Expense bynt_list_main__Expense;
typedef struct bynt_main__Expense bynt_main__Expense;
struct bynt_span_str {
    byn_str* ptr;
    int64_t len;
};
struct bynt_list_str {
    byn_str* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_span_main__Expense {
    bynt_main__Expense* ptr;
    int64_t len;
};
struct bynt_list_main__Expense {
    bynt_main__Expense* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_main__Expense {
    byn_str payer;
    bynt_list_str participants;
};