vtab bynh_vtab_main__Square_main__IShape
again bynh_vtab_main__Square_main__IShape
slot area
slot times
slot describe
slot get_name
vtab bynh_vtab_main__Circle_main__IShape
again bynh_vtab_main__Circle_main__IShape
slot area
slot times
slot describe
slot get_name
count 2
static const struct byn_vt_main__IShape bynh_vtab_main__Square_main__IShape = { bynh_vt_main__Square_main__IShape_area, bynh_vt_main__Square_main__IShape_times, bynh_vt_main__Square_main__IShape_describe, bynh_vt_main__Square_main__IShape_get_name };
static const struct byn_vt_main__IShape bynh_vtab_main__Circle_main__IShape = { bynh_vt_main__Circle_main__IShape_area, bynh_vt_main__Circle_main__IShape_times, bynh_vt_main__Circle_main__IShape_describe, bynh_vt_main__Circle_main__IShape_get_name };
helper bynh_vt_main__Square_main__IShape_area
static int64_t bynh_vt_main__Square_main__IShape_area(void* self) {
    return byn_main__Square__area((bynt_main__Square*)self);
}
helper bynh_vt_main__Square_main__IShape_times
static int64_t bynh_vt_main__Square_main__IShape_times(void* self, int64_t a0) {
    return byn_main__Square__times((bynt_main__Square*)self, a0);
}
helper bynh_vt_main__Square_main__IShape_describe
static void bynh_vt_main__Square_main__IShape_describe(void* self) {
    byn_main__Square__describe((bynt_main__Square*)self);
}
helper bynh_vt_main__Square_main__IShape_get_name
static byn_str bynh_vt_main__Square_main__IShape_get_name(void* self) {
    return byn_main__Square__get_name((bynt_main__Square*)self);
}
helper bynh_vt_main__Circle_main__IShape_area
static int64_t bynh_vt_main__Circle_main__IShape_area(void* self) {
    return byn_main__Circle__area((bynt_main__Circle*)self);
}
helper bynh_vt_main__Circle_main__IShape_times
static int64_t bynh_vt_main__Circle_main__IShape_times(void* self, int64_t a0) {
    return byn_main__Circle__times((bynt_main__Circle*)self, a0);
}
helper bynh_vt_main__Circle_main__IShape_describe
static void bynh_vt_main__Circle_main__IShape_describe(void* self) {
    byn_main__Circle__describe((bynt_main__Circle*)self);
}
helper bynh_vt_main__Circle_main__IShape_get_name
static byn_str bynh_vt_main__Circle_main__IShape_get_name(void* self) {
    return byn_main__Circle__get_name((bynt_main__Circle*)self);
}