typedef struct bynt_opt_f64 bynt_opt_f64;
typedef struct bynt_opt_f32 bynt_opt_f32;
struct bynt_opt_f64 {
    bool has;
    double value;
};
struct bynt_opt_f32 {
    bool has;
    float value;
};