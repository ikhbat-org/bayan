vtab bynh_vtab_main__Square_main__IShape
again bynh_vtab_main__Square_main__IShape
slot area
slot describe
slot get_kind
vtab bynh_vtab_main__Circle_main__IShape
again bynh_vtab_main__Circle_main__IShape
slot area
slot describe
slot get_kind
count 2
static const struct byn_vt_main__IShape bynh_vtab_main__Square_main__IShape = { bynh_vt_main__Square_main__IShape_area, bynh_vt_main__Square_main__IShape_describe, bynh_vt_main__Square_main__IShape_get_kind };
static const struct byn_vt_main__IShape bynh_vtab_main__Circle_main__IShape = { bynh_vt_main__Circle_main__IShape_area, bynh_vt_main__Circle_main__IShape_describe, bynh_vt_main__Circle_main__IShape_get_kind };
helper bynh_vt_main__Square_main__IShape_area
static int64_t bynh_vt_main__Square_main__IShape_area(void* self) {
    return byn_main__Square__area((bynt_main__Square*)self);
}
helper bynh_vt_main__Square_main__IShape_describe
static byn_str bynh_vt_main__Square_main__IShape_describe(void* self) {
    return byn_main__Square__describe((bynt_main__Square*)self);
}
helper bynh_vt_main__Square_main__IShape_get_kind
static byn_str bynh_vt_main__Square_main__IShape_get_kind(void* self) {
    return byn_main__Square__get_kind((bynt_main__Square*)self);
}
helper bynh_vt_main__Circle_main__IShape_area
static int64_t bynh_vt_main__Circle_main__IShape_area(void* self) {
    return byn_main__Circle__area((bynt_main__Circle*)self);
}
helper bynh_vt_main__Circle_main__IShape_describe
static byn_str bynh_vt_main__Circle_main__IShape_describe(void* self) {
    return byn_main__Circle__describe((bynt_main__Circle*)self);
}
helper bynh_vt_main__Circle_main__IShape_get_kind
static byn_str bynh_vt_main__Circle_main__IShape_get_kind(void* self) {
    return byn_main__Circle__get_kind((bynt_main__Circle*)self);
}