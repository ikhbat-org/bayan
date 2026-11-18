typedef struct bynt_arr2_str bynt_arr2_str;
typedef struct bynt_map_str_opt_str bynt_map_str_opt_str;
typedef struct bynt_opt_str bynt_opt_str;
struct bynt_arr2_str {
    byn_str v[2];
};
struct bynt_map_str_opt_str {
    byn_map_hdr h;
    byn_str* keys;
    bynt_opt_str* vals;
};
struct bynt_opt_str {
    bool has;
    byn_str value;
};