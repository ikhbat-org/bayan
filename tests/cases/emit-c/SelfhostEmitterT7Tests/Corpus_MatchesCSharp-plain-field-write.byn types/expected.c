typedef struct bynt_arr2_main__Mode bynt_arr2_main__Mode;
typedef struct bynt_main__Particle bynt_main__Particle;
typedef struct bynt_main__Mode bynt_main__Mode;
struct bynt_main__Mode {
    bool inText;
    int64_t braceDepth;
};
struct bynt_arr2_main__Mode {
    bynt_main__Mode v[2];
};
struct bynt_main__Particle {
    double life;
};