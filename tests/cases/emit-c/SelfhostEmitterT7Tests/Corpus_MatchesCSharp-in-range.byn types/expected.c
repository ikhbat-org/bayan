typedef struct bynt_arr3_i32 bynt_arr3_i32;
typedef struct bynt_opt_i32 bynt_opt_i32;
struct bynt_arr3_i32 {
    int32_t v[3];
};
struct bynt_opt_i32 {
    bool has;
    int32_t value;
};