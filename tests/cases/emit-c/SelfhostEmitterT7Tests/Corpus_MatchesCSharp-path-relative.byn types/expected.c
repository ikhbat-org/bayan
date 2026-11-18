typedef struct bynt_arr16_tup2_str_str bynt_arr16_tup2_str_str;
typedef struct bynt_tup2_str_str bynt_tup2_str_str;
struct bynt_tup2_str_str {
    byn_str item1;
    byn_str item2;
};
struct bynt_arr16_tup2_str_str {
    bynt_tup2_str_str v[16];
};