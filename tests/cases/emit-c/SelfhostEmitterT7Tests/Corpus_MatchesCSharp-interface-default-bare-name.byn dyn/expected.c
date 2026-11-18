vtab bynh_vtab_main__Sq_main__IShape
again bynh_vtab_main__Sq_main__IShape
slot area
slot twice
vtab bynh_vtab_main__Label_main__IShape
again bynh_vtab_main__Label_main__IShape
slot area
slot twice
count 2
static const struct byn_vt_main__IShape bynh_vtab_main__Sq_main__IShape = { bynh_vt_main__Sq_main__IShape_area, bynh_vt_main__Sq_main__IShape_twice };
static const struct byn_vt_main__IShape bynh_vtab_main__Label_main__IShape = { bynh_vt_main__Label_main__IShape_area, bynh_vt_main__Label_main__IShape_twice };
helper bynh_vt_main__Sq_main__IShape_area
static int64_t bynh_vt_main__Sq_main__IShape_area(void* self) {
    return byn_main__Sq__area((bynt_main__Sq*)self);
}
helper bynh_vt_main__Sq_main__IShape_twice
static int64_t bynh_vt_main__Sq_main__IShape_twice(void* self) {
    return byn_main__Sq__twice((bynt_main__Sq*)self);
}
helper bynh_vt_main__Label_main__IShape_area
static int64_t bynh_vt_main__Label_main__IShape_area(void* self) {
    return byn_main__Label__area((bynt_main__Label*)self);
}
helper bynh_vt_main__Label_main__IShape_twice
static int64_t bynh_vt_main__Label_main__IShape_twice(void* self) {
    return byn_main__Label__twice((bynt_main__Label*)self);
}