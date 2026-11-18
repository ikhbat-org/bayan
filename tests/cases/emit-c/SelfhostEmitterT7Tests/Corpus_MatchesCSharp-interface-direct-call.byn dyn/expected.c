vtab bynh_vtab_main__Rect_main__IShape
again bynh_vtab_main__Rect_main__IShape
slot area
slot times
slot get_name
count 1
static const struct byn_vt_main__IShape bynh_vtab_main__Rect_main__IShape = { bynh_vt_main__Rect_main__IShape_area, bynh_vt_main__Rect_main__IShape_times, bynh_vt_main__Rect_main__IShape_get_name };
helper bynh_vt_main__Rect_main__IShape_area
static int64_t bynh_vt_main__Rect_main__IShape_area(void* self) {
    return byn_main__Rect__area((bynt_main__Rect*)self);
}
helper bynh_vt_main__Rect_main__IShape_times
static int64_t bynh_vt_main__Rect_main__IShape_times(void* self, int64_t a0) {
    return byn_main__Rect__times((bynt_main__Rect*)self, a0);
}
helper bynh_vt_main__Rect_main__IShape_get_name
static byn_str bynh_vt_main__Rect_main__IShape_get_name(void* self) {
    return byn_main__Rect__get_name((bynt_main__Rect*)self);
}