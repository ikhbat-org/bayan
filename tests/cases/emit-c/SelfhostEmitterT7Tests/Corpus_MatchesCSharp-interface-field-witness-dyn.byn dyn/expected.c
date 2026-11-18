vtab bynh_vtab_main__Person_main__INamed
again bynh_vtab_main__Person_main__INamed
slot greet
slot get_name
count 1
static const struct byn_vt_main__INamed bynh_vtab_main__Person_main__INamed = { bynh_vt_main__Person_main__INamed_greet, bynh_vt_main__Person_main__INamed_get_name };
helper bynh_vt_main__Person_main__INamed_greet
static byn_str bynh_vt_main__Person_main__INamed_greet(void* self) {
    return byn_main__Person__greet((bynt_main__Person*)self);
}
helper bynh_vt_main__Person_main__INamed_get_name
static byn_str bynh_vt_main__Person_main__INamed_get_name(void* self) {
    return ((bynt_main__Person*)self)->name;
}